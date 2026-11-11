# frozen_string_literal: true

require 'rails_helper'
require 'active_storage/service/s3_service'

# Production stores uploads and call recordings on S3, but the test and
# development environments use disk, so nothing else exercises the AWS SDK.
# These run the same calls against the SDK's stubbed client so that an
# aws-sdk-s3 upgrade which breaks them fails here, not in production.
RSpec.describe 'AWS S3 usage' do
  let(:credentials) do
    { access_key_id: 'test-key', secret_access_key: 'test-secret', region: 'us-east-1' }
  end

  describe 'the Active Storage service configured as "amazon"' do
    let(:service) do
      ActiveStorage::Service::S3Service.new(bucket: 'test-bucket', stub_responses: true, **credentials)
    end
    let(:body) { 'logo-bytes' }
    let(:checksum) { Digest::MD5.base64digest(body) }

    it 'is the service production is configured to use' do
      config = Rails.application.config.active_storage.service_configurations
      expect(config.dig('amazon', 'service')).to eq('S3')
    end

    it 'uploads a file' do
      expect { service.upload('some-key', StringIO.new(body), checksum: checksum, content_type: 'image/png') }
        .not_to raise_error
    end

    it 'downloads a file' do
      service.client.client.stub_responses(:get_object, body: body)
      expect(service.download('some-key')).to eq(body)
    end

    it 'checks for and deletes a file' do
      expect(service.exist?('some-key')).to be(true)
      expect { service.delete('some-key') }.not_to raise_error
    end

    it 'signs a time-limited download URL' do
      url = service.url('some-key', expires_in: 5.minutes, filename: ActiveStorage::Filename.new('logo.png'),
                                    disposition: :inline, content_type: 'image/png')
      uri = URI.parse(url)

      expect(uri.host).to eq('test-bucket.s3.amazonaws.com')
      expect(uri.path).to eq('/some-key')
      expect(uri.query).to include('X-Amz-Expires=300', 'X-Amz-Signature=')
    end
  end

  describe 'call recording links (config/initializers/aws.rb)' do
    it 'presigns a GET URL for a recording' do
      client = Aws::S3::Client.new(stub_responses: true, **credentials)
      url = Aws::S3::Presigner.new(client: client)
                              .presigned_url(:get_object, bucket: 'recordings', key: 'call.wav', expires_in: 600)
      uri = URI.parse(url)

      expect(uri.host).to eq('recordings.s3.amazonaws.com')
      expect(uri.path).to eq('/call.wav')
      expect(uri.query).to include('X-Amz-Expires=600', 'X-Amz-Signature=')
    end
  end
end
