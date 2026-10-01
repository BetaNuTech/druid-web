require 'rails_helper'

RSpec.describe YodaBot::ErrorNotifier do
  include ActiveJob::TestHelper

  let(:backtrace) do
    [
      "#{Gem.dir}/gems/activerecord-6.1.7.10/lib/active_record/base.rb:1:in 'gem_method'",
      "#{Rails.root}/app/models/lead.rb:42:in 'Lead#foo'",
      "#{Rails.root}/app/controllers/leads_controller.rb:10:in 'LeadsController#show'"
    ]
  end

  def error(message = "undefined method `code' for nil", trace: backtrace)
    NoMethodError.new(message).tap { |e| e.set_backtrace(trace) }
  end

  def enqueued_args
    expect(enqueued_jobs.size).to eq(1)
    job = enqueued_jobs.first
    expect(job[:job]).to eq(YodaBotErrorJob)
    ActiveJob::Arguments.deserialize(job[:args]).first.symbolize_keys
  end

  around do |example|
    with_env(SLACK_CORP_YODABOT_OAUTH_TOKEN: 'xoxb-yoda', ERROR_SLACK_CHANNEL: '#bluesky-errors') do
      example.run
    end
  end

  before { ActiveJob::Base.queue_adapter = :test }

  it 'enqueues a Yoda post describing a request error' do
    controller = instance_double(LeadsController, controller_path: 'leads', action_name: 'show')

    described_class.call(error, env: { 'action_controller.instance' => controller })

    args = enqueued_args
    expect(args[:channel]).to eq('#bluesky-errors')
    expect(args[:error_class]).to eq('NoMethodError')
    expect(args[:origin]).to eq('leads#show')
    # Skips gem frames to find our own code.
    expect(args[:location]).to eq('app/models/lead.rb:42 in Lead#foo')
  end

  it 'describes the data passed to ErrorNotification.send, without the host' do
    described_class.call(StandardError.new('Sync failed'), data: { host: 'www.blue-sky.app', lead_id: 'abc' })

    args = enqueued_args
    expect(args[:data]).to eq('lead_id: abc')
    expect(args[:host]).to eq('www.blue-sky.app')
    expect(args[:location]).to be_nil
    expect(args[:origin]).to be_nil
  end

  it 'does nothing without a token' do
    with_env(SLACK_CORP_YODABOT_OAUTH_TOKEN: '') do
      described_class.call(error, {})
    end

    expect(enqueued_jobs).to be_empty
  end

  it 'does nothing when the channel is blank' do
    with_env(ERROR_SLACK_CHANNEL: '') do
      described_class.call(error, {})
    end

    expect(enqueued_jobs).to be_empty
  end

  it 'the fingerprint ignores the message and line, so repeats group together' do
    other_trace = backtrace.dup
    other_trace[1] = other_trace[1].sub(':42:', ':999:')
    a = error
    b = error("undefined method `code' for nil (property 1002edge)", trace: other_trace)

    expect(described_class.fingerprint(b, described_class.app_frame(b.backtrace)))
      .to eq(described_class.fingerprint(a, described_class.app_frame(a.backtrace)))
  end

  it 'groups backtrace-less errors by message, ignoring ids' do
    a = StandardError.new('Yardi sync failed for lead 123')
    b = StandardError.new('Yardi sync failed for lead 456')
    c = StandardError.new('Something else')

    expect(described_class.fingerprint(a, nil)).to eq(described_class.fingerprint(b, nil))
    expect(described_class.fingerprint(a, nil)).not_to eq(described_class.fingerprint(c, nil))
  end

  it 'never raises, even when enqueuing fails' do
    allow(YodaBotErrorJob).to receive(:perform_later).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect { described_class.call(error, {}) }.not_to raise_error
  end
end
