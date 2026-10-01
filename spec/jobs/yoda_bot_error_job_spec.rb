require 'rails_helper'

RSpec.describe YodaBotErrorJob, type: :job do
  let(:args) do
    {
      fingerprint: 'abc',
      channel: '#bluesky-errors',
      error_class: 'NoMethodError',
      message: "undefined method `code' for nil",
      location: 'app/models/lead.rb:42 in Lead#foo',
      origin: 'leads#show',
      host: 'www.blue-sky.app'
    }
  end
  let(:client) { instance_double(Slack::Web::Client) }

  around do |example|
    with_env(SLACK_CORP_YODABOT_OAUTH_TOKEN: 'xoxb-yoda') { example.run }
  end

  it 'posts to the channel as the corporate Yoda Bot' do
    allow(ErrorAlert).to receive(:claim_post).with('abc').and_return(0)
    expect(Slack::Web::Client).to receive(:new).with(token: 'xoxb-yoda').and_return(client)
    expect(client).to receive(:chat_postMessage) do |params|
      expect(params[:channel]).to eq('#bluesky-errors')
      expect(params).not_to have_key(:link_names)
      expect(params[:text]).to include('`NoMethodError` in `leads#show`, there is.')
    end

    described_class.perform_now(**args)
  end

  it 'stays silent inside the rate-limit window' do
    allow(ErrorAlert).to receive(:claim_post).and_return(nil)
    expect(Slack::Web::Client).not_to receive(:new)

    described_class.perform_now(**args)
  end

  it 'a failed post is logged, never reported through ErrorNotification' do
    allow(ErrorAlert).to receive(:claim_post).and_return(0)
    allow(Slack::Web::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat_postMessage).and_raise(Slack::Web::Api::Errors::SlackError.new('channel_not_found'))
    expect(ErrorNotification).not_to receive(:send)
    expect(Rails.logger).to receive(:error).with(/YodaBotErrorJob: could not post/)

    expect { described_class.perform_now(**args) }.not_to raise_error
  end

  it 'does nothing without a token' do
    expect(ErrorAlert).not_to receive(:claim_post)

    with_env(SLACK_CORP_YODABOT_OAUTH_TOKEN: '') do
      described_class.perform_now(**args)
    end
  end
end
