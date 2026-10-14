require 'rails_helper'

RSpec.describe Residents::Adapters::YardiBackup do
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:property) { create(:property, phone: '6155550000') }
  let!(:voyager_listing) do
    create(:property_listing, property: property, source: voyager_source, code: '1002edge', active: true)
  end
  let!(:unit) { create(:unit, property: property, unit: '406') }

  # Stands in for a connected Yardi::Backup::Database
  let(:backup) do
    Class.new do
      attr_accessor :rows

      def initialize
        @rows = []
      end

      def open
        yield self
      end

      def residents(_code) = rows
    end.new
  end

  def person(**attributes)
    defaults = { tenant_code: 't0225446', prospect_code: 'p0518217', prospect_hmy: 1, first_name: 'Zoe', last_name: 'Ellis',
                 unit: '0406', status: 'notice', relationship: 'Tenant', phones: ['2562636836'], email: 'zoe@example.com' }
    Yardi::Backup::Database::Resident.new(**defaults.merge(attributes))
  end

  let(:service) { described_class.new(property, db: backup) }

  describe '#processResidents' do
    it 'imports tenants and household members with status, relationship, unit and contacts' do
      backup.rows = [
        person,
        person(prospect_code: 'p0523236', first_name: 'Hunter', last_name: 'Brown', relationship: 'Roommate', status: 'notice',
               phones: %w[9312124688 6155550000 6155550111], email: nil),
        person(tenant_code: 't0000001', prospect_code: nil, first_name: 'Past', last_name: 'Tenant', status: 'past', unit: '0101',
               phones: [], email: nil)
      ]

      response = service.processResidents

      expect(response[:status]).to eq(:ok)
      expect(response[:stats]).to include(created: 3, updated: 0, former: 0, members: 1)
      zoe = Resident.find_by(residentid: 't0225446')
      expect(zoe).to have_attributes(status: 'current', yardi_status: 'notice', relationship: 'Tenant', unit_id: unit.id,
                                     first_name: 'Zoe', last_name: 'Ellis', property_id: property.id)
      expect(zoe.detail).to have_attributes(phone1: '2562636836', phone2: nil, email: 'zoe@example.com')
      hunter = Resident.find_by(residentid: 't0225446-p0523236')
      expect(hunter).to have_attributes(relationship: 'Roommate', status: 'current', unit_id: unit.id)
      expect(hunter.detail).to have_attributes(phone1: '9312124688', phone2: '6155550111') # the property's own number is dropped
      expect(Resident.find_by(residentid: 't0000001')).to have_attributes(status: 'former', yardi_status: 'past', unit_id: nil)
    end

    it 'updates existing rows in place and leaves what Yardi does not provide alone' do
      existing = create(:resident, property: property, residentid: 't0225446', status: 'current', first_name: 'Zoey',
                                   last_name: 'Ellis', address1: '5833 Nolensville Pike', lead: create(:lead, property: property))
      create(:resident_detail, resident: existing, phone1: '0000000000', phone1_type: 'Cell', email: nil)
      backup.rows = [person]

      response = service.processResidents

      expect(response[:stats]).to include(created: 0, updated: 1)
      existing.reload
      expect(existing).to have_attributes(first_name: 'Zoe', address1: '5833 Nolensville Pike', yardi_status: 'notice')
      expect(existing.lead_id).to be_present
      expect(existing.detail).to have_attributes(phone1: '2562636836', phone1_type: 'Cell', email: 'zoe@example.com')
    end

    it 'marks Yardi-imported residents the backup no longer lists as former, but not manual ones' do
      gone = create(:resident, property: property, residentid: 't0000009', status: 'current')
      soap_roommate = create(:resident, property: property, residentid: 'r0023191', status: 'current')
      manual = create(:resident, property: property, residentid: 'R12345678', status: 'current')
      elsewhere = create(:resident, residentid: 't0000010', status: 'current')
      backup.rows = [person, person(prospect_code: 'p1', first_name: 'A', last_name: 'B', relationship: 'Spouse', phones: [])]

      response = service.processResidents

      expect(response[:stats][:former]).to eq(2)
      expect(gone.reload.status).to eq('former')
      expect(soap_roommate.reload.status).to eq('former')
      expect(manual.reload.status).to eq('current')
      expect(elsewhere.reload.status).to eq('current')
    end

    it 'changes nothing when the listing looks incomplete' do
      4.times { |i| create(:resident, property: property, residentid: "t000000#{i}", status: 'current') }
      backup.rows = [person]

      response = service.processResidents

      expect(response[:status]).to eq(:warn)
      expect(response[:errors].first).to include('looks incomplete')
      expect(Resident.where(property: property, status: 'current').count).to eq(4)
      expect(Resident.find_by(residentid: 't0225446')).to be_nil
    end

    it 'changes nothing when the listing is empty' do
      backup.rows = []
      expect(service.processResidents[:status]).to eq(:warn)
    end

    it 'reports but does not write in a dry run' do
      gone = create(:resident, property: property, residentid: 't0000009', status: 'current')
      backup.rows = [person, person(prospect_code: 'p1', first_name: 'A', last_name: 'B', relationship: 'Spouse', phones: [])]

      response = described_class.new(property, db: backup, dry_run: true).processResidents

      expect(response[:stats]).to include(created: 2, former: 1)
      expect(response[:stats][:by_relationship]).to eq('Tenant' => 1, 'Spouse' => 1)
      expect(Resident.find_by(residentid: 't0225446')).to be_nil
      expect(gone.reload.status).to eq('current')
    end
  end

  describe '.sync' do
    it 'imports every active property through one connection and skips quietly while the backup restores' do
      backup.rows = [person]
      expect(described_class.sync([property], false, database: backup)).to be true
      expect(Resident.find_by(residentid: 't0225446')).to be_present

      failing = Class.new do
        def self.open(**)
          raise Yardi::Backup::Database::Unavailable, 'restoring'
        end
      end
      expect(described_class.sync([property], false, database: failing)).to be false
    end
  end
end
