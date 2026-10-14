require 'rails_helper'

RSpec.describe YodaBotMessageJob, type: :job do
  let(:client) { instance_double(Slack::Web::Client) }

  around do |example|
    with_env(SLACK_CORP_YODABOT_OAUTH_TOKEN: 'xoxb-yoda') { example.run }
  end

  it 'posts the line to the channel as the corporate Yoda Bot without link names' do
    expect(Slack::Web::Client).to receive(:new).with(token: 'xoxb-yoda').and_return(client)
    expect(client).to receive(:chat_postMessage).with(channel: '#bluesky-resident-blocks', text: 'Vintage Edge: blocked')

    described_class.perform_now(channel: '#bluesky-resident-blocks', text: 'Vintage Edge: blocked')
  end

  it 'does nothing without a channel' do
    expect(Slack::Web::Client).not_to receive(:new)
    described_class.perform_now(channel: nil, text: 'x')
  end

  it 'only logs a Slack failure' do
    allow(Slack::Web::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::SlackError, 'channel_not_found')
    expect { described_class.perform_now(channel: '#nope', text: 'x') }.not_to raise_error
  end
end
