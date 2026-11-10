# frozen_string_literal: true

require 'rails_helper'

# The expected values were captured from FroalaEditorSDK::S3.data_hash
# (froala-editor-sdk 1.4.0) before that gem was replaced by this port.
RSpec.describe Froala::S3Upload do
  include ActiveSupport::Testing::TimeHelpers

  let(:options) do
    {
      bucket: 'example-bucket',
      region: 'us-east-2',
      keyStart: 'editor_asset',
      acl: 'public-read',
      accessKey: 'AKIAEXAMPLE',
      secretKey: 'example-secret'
    }
  end

  around do |example|
    travel_to(Time.utc(2026, 11, 10, 12, 0, 0)) { example.run }
  end

  it 'matches what the froala-editor-sdk gem produced' do
    expect(described_class.data_hash(options)).to eq(
      bucket: 'example-bucket',
      region: 's3-us-east-2',
      keyStart: 'editor_asset',
      params: {
        acl: 'public-read',
        policy: 'eyJleHBpcmF0aW9uIjoiMjAyNi0xMS0xMFQyMjowMDowMFoiLCJjb25kaXRpb25zIjpbWyJzdGFydHMtd2l0aCIsIiRrZXkiLCJlZGl0b3JfYXNzZXQiXSxbInN0YXJ0cy13aXRoIiwiJENvbnRlbnQtdHlwZSIsIiJdLHsieC1yZXF1ZXN0ZWQtd2l0aCI6InhociJ9LHsieC1hbXotYWxnb3JpdGhtIjoiQVdTNC1ITUFDLVNIQTI1NiJ9LHsieC1hbXotZGF0ZSI6IjIwMjYxMTEwVDAwMDAwMFoifSx7IngtYW16LWNyZWRlbnRpYWwiOiJBS0lBRVhBTVBMRS8yMDI2MTExMC91cy1lYXN0LTIvczMvYXdzNF9yZXF1ZXN0In0seyJidWNrZXQiOiJleGFtcGxlLWJ1Y2tldCJ9LHsiYWNsIjoicHVibGljLXJlYWQifSx7InN1Y2Nlc3NfYWN0aW9uX3N0YXR1cyI6IjIwMSJ9XX0=',
        'x-amz-algorithm': 'AWS4-HMAC-SHA256',
        'x-amz-credential': 'AKIAEXAMPLE/20261110/us-east-2/s3/aws4_request',
        'x-amz-date': '20261110T000000Z',
        'x-amz-signature': 'a4183c7c016c1d6853dc98439997be63eca21ffcfa2d59b62ac0e4f158357872'
      }
    )
  end

  it 'limits uploads to the key prefix, the bucket and the ACL' do
    policy = JSON.parse(Base64.decode64(described_class.data_hash(options)[:params][:policy]))

    expect(policy['expiration']).to eq('2026-11-10T22:00:00Z')
    expect(policy['conditions']).to include(
      ['starts-with', '$key', 'editor_asset'],
      { 'bucket' => 'example-bucket' },
      { 'acl' => 'public-read' }
    )
  end

  it 'treats a missing or legacy "s3" region as us-east-1' do
    [nil, 's3', 'us-east-1'].each do |region|
      data = described_class.data_hash(options.merge(region: region))

      expect(data[:region]).to eq('s3')
      expect(data[:params][:'x-amz-credential']).to eq('AKIAEXAMPLE/20261110/us-east-1/s3/aws4_request')
    end
  end

  it 'does not modify the options it is given' do
    expect { described_class.data_hash(options.freeze) }.not_to raise_error
  end
end
