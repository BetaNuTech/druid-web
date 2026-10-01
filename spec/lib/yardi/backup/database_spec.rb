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

  describe '#resident_phones' do
    it 'returns the callers who are current residents of the property' do
      stub_queries(/FROM TENANT t/ => [{ 'SPHONENUM0' => '6155550123', 'SPHONENUM3' => '(615) 555-0999' }])

      expect(database.resident_phones('1002edge', %w[6155550123 6155550555])).to eq(Set['6155550123'])
      expect(executed.last).to include('t.ISTATUS IN (0, 2, 3, 4)')
    end
  end
end
