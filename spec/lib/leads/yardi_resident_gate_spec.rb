require 'rails_helper'

RSpec.describe Leads::YardiResidentGate do
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:property) { create(:property, phone: '6155550000', leasing_phone: nil, maintenance_phone: nil) }
  let!(:voyager_listing) do
    create(:property_listing, property: property, source: voyager_source, code: '1002edge', active: true)
  end

  # Stands in for Yardi::Backup::Database
  let(:backup) do
    Class.new do
      attr_accessor :residents, :opens, :failure, :closed, :queries

      def initialize
        @residents = {}
        @opens = 0
        @closed = 0
        @queries = []
      end

      def configured? = true

      def connect_with_retries(**)
        @opens += 1
        raise failure if failure

        self
      end

      def close
        @closed += 1
      end

      def residents_by_contact(_code, phones:, emails: [])
        @queries << { phones: phones, emails: emails }
        residents.slice(*(phones + emails))
      end
    end.new
  end

  let(:gate) { described_class.new(database: backup) }

  def resident(**attributes)
    defaults = { tenant_code: 't0225446', prospect_code: 'p0518217', prospect_hmy: 519_322, first_name: 'Zoe',
                 last_name: 'Ellis', unit: '0406', status: 'notice', relationship: 'Tenant', phones: ['2562636836'], email: nil }
    Yardi::Backup::Database::Resident.new(**defaults.merge(attributes))
  end

  def lead(state: 'open', phone1: '2562636836', phone2: nil, email: nil, last_name: 'Caller', user: nil)
    create(:lead, property: property, state: state, user: user, phone1: phone1, phone2: phone2, email: email,
                  first_name: 'Pat', last_name: last_name, classification: nil, remoteid: nil)
  end

  describe '#screen' do
    it 'separates residents to close out, matches to review, and clear leads' do
      backup.residents = { '2562636836' => [resident], 'zoe@example.com' => [resident(email: 'zoe@example.com')] }
      open_lead = lead
      showing = lead(state: 'showing', phone1: '6155550199', email: 'Zoe@Example.com')
      clear = lead(phone1: '6155550123')

      result = gate.screen(property, [open_lead, showing, clear])

      expect(result[:residents].map(&:first)).to eq([open_lead])
      expect(result[:review].map(&:first)).to eq([showing])
      expect(result[:clear]).to eq([clear])
      expect(backup.queries).to eq([{ phones: %w[2562636836 6155550199 6155550123], emails: ['zoe@example.com'] }])
    end

    it 'ignores the property’s own numbers and placeholder values' do
      backup.residents = { '6155550000' => [resident(phones: ['6155550000'])] }
      office_caller = lead(phone1: '6155550000', phone2: '0000000000')

      result = gate.screen(property, [office_caller])

      expect(result[:clear]).to eq([office_caller])
      expect(backup.queries).to be_empty
    end

    it 'requires a last-name match for guarantors' do
      backup.residents = { '2562636836' => [resident(first_name: 'Pat', last_name: 'Parent', relationship: 'Guarantor')] }
      other_name = lead(last_name: 'Caller')
      same_name = lead(last_name: 'parent')

      result = gate.screen(property, [other_name, same_name])

      expect(result[:clear]).to eq([other_name])
      expect(result[:residents].map(&:first)).to eq([same_name])
    end

    it 'opens the backup once per run and only when there are leads' do
      expect(gate.screen(property, [])).to eq(clear: [], residents: [], review: [])
      expect(backup.opens).to eq(0)

      gate.screen(property, [lead(phone1: '6155550101')])
      gate.screen(property, [lead(phone1: '6155550102')])
      gate.close

      expect(backup.opens).to eq(1)
      expect(backup.closed).to eq(1)
    end

    it 'remembers a failed open for the rest of the run' do
      backup.failure = Yardi::Backup::Database::Unavailable.new('restoring')
      leads = [lead(phone1: '6155550101')]

      expect { gate.screen(property, leads) }.to raise_error(Yardi::Backup::Database::Unavailable)
      expect { gate.screen(property, leads) }.to raise_error(Yardi::Backup::Database::Unavailable)
      expect(backup.opens).to eq(1)
    end

    it 'passes everything through when the backup is not configured' do
      allow(backup).to receive(:configured?).and_return(false)
      leads = [lead]

      expect(gate.screen(property, leads)[:clear]).to eq(leads)
      expect(backup.opens).to eq(0)
    end
  end

  describe '#close_out and #hold' do
    it 'invalidates an open lead as a resident with the Yardi details in the memo' do
      open_lead = lead

      expect(gate.close_out(open_lead, resident, note_prefix: 'Yardi sync')).to be true

      expect(open_lead.reload).to have_attributes(state: 'invalidated', classification: 'resident')
      expect(open_lead.lead_transitions.last.memo)
        .to eq('Yardi sync: matches Yardi resident Zoe Ellis, unit 0406, notice (Tenant t0225446)')
      expect(Note.where(notable: property).last.content)
        .to include('Resident block:', "(Lead #{open_lead.id}) closed before the Yardi push, matches resident Zoe Ellis")
    end

    it 'leaves a lead in showing alone apart from one note' do
      showing = lead(state: 'showing')

      2.times { gate.hold(showing, resident, note_prefix: 'Yardi sync') }

      expect(showing.reload).to have_attributes(state: 'showing', classification: nil)
      notes = Note.where(notable: showing).where('content LIKE ?', 'Yardi sync: not sent to Yardi%')
      expect(notes.count).to eq(1)
      expect(notes.first.content).to include('Zoe Ellis, unit 0406')
      expect(Note.where(notable: property).where('content LIKE ?', 'Resident block:%').count).to eq(1)
    end

    it 'writes nothing in a dry run' do
      dry = described_class.new(database: backup, dry_run: true)
      open_lead = lead

      expect(dry.close_out(open_lead, resident)).to be true
      dry.hold(open_lead, resident)

      expect(open_lead.reload.state).to eq('open')
      expect(Note.where(notable: open_lead).where('content LIKE ?', '%not sent to Yardi%')).not_to exist
    end
  end

  describe '#shared_database' do
    it 'lets a database: taker use the gate’s connection' do
      yielded = nil
      gate.shared_database.open { |db| yielded = db }
      expect(yielded).to eq(backup)
      expect(backup.opens).to eq(1)
    end
  end
end
