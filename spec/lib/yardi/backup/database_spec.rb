require 'rails_helper'
require 'tiny_tds'

RSpec.describe Yardi::Backup::Database do
  let(:database) { described_class.new(env: {}) }
  let(:client) { double('TinyTds::Client') }
  let(:executed) { [] }

  # Answer each query with the first canned result whose pattern matches it
  def stub_queries(responses)
    allow(client).to receive(:escape) { |value| value.gsub("'", "''") }
    allow(client).to receive(:execute) do |sql|
      executed << sql
      pattern, rows = responses.find { |pattern, _rows| sql.match?(pattern) }
      raise "unexpected query: #{sql}" unless pattern
      raise rows if rows.is_a?(Exception)

      double(each: rows)
    end
    database.instance_variable_set(:@client, client)
  end

  describe '#connect' do
    it 'refuses to connect without the backup database settings' do
      expect { described_class.new(env: { 'YARDI_BACKUP_DB_HOST' => 'x' }).connect }
        .to raise_error(described_class::ConfigurationError, /YARDI_BACKUP_DB_NAME, YARDI_BACKUP_DB_USER, YARDI_BACKUP_DB_PASS/)
    end
  end

  describe '#data_as_of' do
    let(:newest_activity) { Time.utc(2026, 10, 1, 21, 50, 21) }
    let(:restored_at) { Time.utc(2026, 10, 1, 22, 29, 16) }

    it 'returns the restored log backup time, read as Eastern wall-clock time' do
      stub_queries(
        /PROSPECT_HISTORY/ => [{ 'newest' => newest_activity }],
        /restorehistory/ => [{ 'restore_date' => restored_at, 'backup_finish_date' => Time.utc(2026, 10, 1, 18, 0, 19) }]
      )
      expect(database.data_as_of).to eq(Time.utc(2026, 10, 1, 22, 0, 19))
    end

    it 'falls back to the newest activity when the backup time is inconsistent' do
      # Read as UTC this backup would predate activity it contains
      stub_queries(
        /PROSPECT_HISTORY/ => [{ 'newest' => newest_activity }],
        /restorehistory/ => [{ 'restore_date' => restored_at, 'backup_finish_date' => Time.utc(2026, 10, 1, 12, 0, 0) }]
      )
      expect(database.data_as_of).to eq(newest_activity)
    end

    it 'falls back to the newest activity when backup history is unreadable' do
      stub_queries(
        /PROSPECT_HISTORY/ => [{ 'newest' => newest_activity }],
        /restorehistory/ => TinyTds::Error.new('permission denied on msdb')
      )
      expect(database.data_as_of).to eq(newest_activity)
    end

    it 'is unavailable when the newest activity cannot be read (a log restore in progress)' do
      stub_queries(/PROSPECT_HISTORY/ => [])
      expect { database.data_as_of }.to raise_error(described_class::Unavailable, /no data time/)

      stub_queries(/PROSPECT_HISTORY/ => [{ 'newest' => nil }])
      expect { described_class.new(env: {}).tap { |db| db.instance_variable_set(:@client, client) }.data_as_of }
        .to raise_error(described_class::Unavailable)
    end

    it 'is unavailable when SQL Server reports the database is restoring' do
      stub_queries(/PROSPECT_HISTORY/ => TinyTds::Error.new("Database 'gazv_live' cannot be opened. It is in the middle of a restore."))
      expect { database.data_as_of }.to raise_error(described_class::Unavailable, /middle of a restore/)
    end
  end

  describe '.open' do
    let(:env) { { 'YARDI_BACKUP_DB_HOST' => 'h', 'YARDI_BACKUP_DB_NAME' => 'n', 'YARDI_BACKUP_DB_USER' => 'u', 'YARDI_BACKUP_DB_PASS' => 'p' } }

    it 'retries across a restore window, then yields a readable database' do
      attempts = 0
      allow(described_class).to receive(:new) do
        attempts += 1
        instance_double(described_class).tap do |db|
          allow(db).to receive(:connect).and_return(db)
          allow(db).to receive(:close)
          if attempts < 3
            allow(db).to receive(:data_as_of).and_raise(described_class::Unavailable, 'no data time')
          else
            allow(db).to receive(:data_as_of).and_return(Time.utc(2026, 10, 14, 16, 0))
          end
        end
      end
      allow(described_class).to receive(:sleep)

      yielded = nil
      described_class.open(env: env, retries: 3, wait: 20) { |db| yielded = db }

      expect(attempts).to eq(3)
      expect(described_class).to have_received(:sleep).with(20).twice
      expect(yielded.data_as_of).to eq(Time.utc(2026, 10, 14, 16, 0))
      expect(yielded).to have_received(:close)
    end

    it 'gives up with Unavailable after the retries' do
      db = instance_double(described_class, close: nil)
      allow(db).to receive(:connect).and_return(db)
      allow(db).to receive(:data_as_of).and_raise(described_class::Unavailable, 'no data time')
      allow(described_class).to receive(:new).and_return(db)
      allow(described_class).to receive(:sleep)

      expect { described_class.open(env: env, retries: 2, wait: 1) { raise 'not reached' } }
        .to raise_error(described_class::Unavailable)
      expect(described_class).to have_received(:sleep).twice
    end

    it 'does not retry a configuration error' do
      allow(described_class).to receive(:sleep)
      expect { described_class.open(env: { 'YARDI_BACKUP_DB_HOST' => 'x' }) { raise 'not reached' } }
        .to raise_error(described_class::ConfigurationError)
      expect(described_class).not_to have_received(:sleep)
    end
  end

  describe '#prospects_by_phone' do
    def card_row(prospect_id, **phones)
      { 'prospect_id' => prospect_id, 'created_at' => 1.day.ago, 'source' => 'Zillow', 'agent' => 'Admin',
        'created_by' => 'leapro', 'status' => 'Prospect', 'first_name' => 'Pat', 'last_name' => 'Caller',
        'relationship' => nil, 'sTelCell' => nil, 'sTelHome' => nil, 'sTelOffice' => nil, 'sTelAlt' => nil }
        .merge(phones.transform_keys(&:to_s))
    end

    it 'matches any of the four phone fields regardless of format' do
      stub_queries(/FROM PROSPECT pr/ => [
        card_row('p0000001', sTelCell: '(615) 555-0123'),
        card_row('p0000002', sTelHome: '+1 615 555 0123'),
        card_row('p0000003', sTelOffice: '9195550123') # same last four, different number
      ])

      index = database.prospects_by_phone("1002edge", ['615-555-0123'])

      expect(index.keys).to eq(['6155550123'])
      expect(index['6155550123'].map(&:prospect_id)).to eq(%w[p0000001 p0000002])
      expect(executed.last).to include("RTRIM(p.SCODE) = '1002edge'", "pr.sTelCell LIKE '%0123'", "pr.sTelAlt LIKE '%0123'")
    end

    it 'skips the query when no valid phone is given' do
      stub_queries({})
      expect(database.prospects_by_phone('1002edge', [nil, '123'])).to eq({})
      expect(executed).to be_empty
    end
  end

  describe '#first_contact_events' do
    it "returns the card's first-contact events with their Voyager event IDs" do
      stub_queries(/FROM PROSPECT_HISTORY ph/ => [{ 'event_id' => BigDecimal('1931457'), 'event_type' => 'Email',
                                                    'date' => Time.utc(2026, 4, 4), 'time' => '10:31 AM',
                                                    'agent' => 'Admin', 'notes' => 'Original note' }])

      events = database.first_contact_events('1002edge', 'p0519843')

      expect(events.size).to eq(1)
      expect(events.first.event_id.to_i).to eq(1931457)
      expect(events.first.occurred_at).to eq(Time.utc(2026, 4, 4, 10, 31))
      expect(executed.last).to include("RTRIM(pr.sCode) = 'p0519843'", 'ph.bFirstContact <> 0')
    end
  end

  describe '#residents_by_contact' do
    def household_row(kind:, **values)
      base = { 'kind' => kind, 'tenant_code' => 't0225446', 'prospect_code' => 'p0518217', 'prospect_hmy' => BigDecimal('519322'),
               'first_name' => 'Zoe', 'last_name' => 'Ellis', 'unit' => '0406', 'istatus' => BigDecimal('4'),
               'relationship' => 'Tenant', 'tel_cell' => nil, 'tel_home' => nil, 'tel_alt' => nil, 'tel_office' => nil,
               'email_1' => nil, 'email_2' => nil, 'move_in' => Time.utc(2026, 2, 20), 'move_out' => nil }
      base.merge((0..9).to_h { |i| ["tel_#{i}", nil] }).merge(values.transform_keys(&:to_s))
    end

    it 'finds tenants and household members by any phone or email, however formatted' do
      stub_queries(/FROM TENANT t/ => [
        household_row(kind: 'tenant', tel_0: '(256) 263-6836', tel_3: '2562636836', email_1: 'ZoeCEllis@gmail.com '),
        household_row(kind: 'member', prospect_code: 'p0523236', prospect_hmy: BigDecimal('532892'), first_name: 'Hunter',
                      last_name: 'Brown', relationship: 'Roommate', istatus: BigDecimal('0'), tel_cell: '+1 931 212 4688'),
        household_row(kind: 'member', prospect_code: 'p0522765', first_name: 'Other', last_name: 'Person',
                      relationship: 'Other', tel_cell: '0000000000', tel_home: '6155556836') # same last four, other number
      ])

      index = database.residents_by_contact('1002edge', phones: ['256-263-6836', '9312124688'], emails: ['zoecellis@gmail.com'])

      expect(index.keys).to match_array(%w[2562636836 9312124688 zoecellis@gmail.com])
      zoe = index['2562636836'].first
      expect(zoe).to have_attributes(tenant_code: 't0225446', status: 'notice', relationship: 'Tenant', unit: '0406',
                                     phones: ['2562636836'], email: 'zoecellis@gmail.com')
      expect(zoe).to be_primary
      expect(zoe.description).to eq('Zoe Ellis, unit 0406, notice (Tenant t0225446)')
      expect(index['zoecellis@gmail.com']).to eq([zoe])
      hunter = index['9312124688'].first
      expect(hunter).to have_attributes(relationship: 'Roommate', status: 'current', prospect_code: 'p0523236')
      expect(hunter).not_to be_primary
      expect(hunter.description).to eq('Hunter Brown, unit 0406, current (Roommate of t0225446, p0523236)')

      sql = executed.last
      expect(sql).to include("RTRIM(p.SCODE) = '1002edge'", 't.ISTATUS IN (0, 2, 3, 4)', 'c.hParent = t.hProspect AND t.hProspect > 0 AND c.hParent > 0',
                             'pr.hMy = t.hProspect AND t.hProspect > 0', "NOT LIKE 'Cancel%'", "h.tel_cell LIKE '%6836'",
                             "h.tel_9 LIKE '%4688'", "LOWER(RTRIM(h.email_1)) IN ('zoecellis@gmail.com')")
    end

    it 'ignores placeholder numbers and skips the query without usable contacts' do
      stub_queries({})
      expect(database.residents_by_contact('1002edge', phones: ['0000000000', '123', nil], emails: ['none'])).to eq({})
      expect(executed).to be_empty
    end
  end

  describe '#residents' do
    it 'lists every tenant and member the import keeps, with the status word' do
      stub_queries(/FROM TENANT t/ => [
        { 'kind' => 'tenant', 'tenant_code' => 't0000001', 'prospect_code' => nil, 'prospect_hmy' => nil, 'first_name' => 'Past',
          'last_name' => 'Tenant', 'unit' => '0101', 'istatus' => BigDecimal('1'), 'relationship' => 'Tenant',
          'tel_cell' => nil, 'tel_home' => nil, 'tel_alt' => nil, 'tel_office' => nil, 'tel_0' => '6155550101',
          'email_1' => nil, 'email_2' => 'past@example.com', 'move_in' => nil, 'move_out' => Time.utc(2025, 1, 31) }
      ])

      residents = database.residents('1002edge')

      expect(residents.size).to eq(1)
      expect(residents.first).to have_attributes(status: 'past', phones: ['6155550101'], email: 'past@example.com',
                                                 move_out: Time.utc(2025, 1, 31))
      expect(executed.last).to include('t.ISTATUS IN (0, 1, 2, 3, 4)')
      expect(executed.last).not_to include('LIKE \'%')
    end
  end
end
