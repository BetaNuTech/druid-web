# frozen_string_literal: true

module Froala
  # Builds the signed S3 POST policy that the Froala editor's
  # `imageUploadToS3` / `fileUploadToS3` options expect.
  #
  # Port of FroalaEditorSDK::S3 from the froala-editor-sdk gem (MIT), which
  # could not stay: it depends on wysiwyg-rails ~> 3.1, and every
  # wysiwyg-rails 3.x release caps railties below 7.0. The editor assets
  # themselves (Froala 3.2.7) are vendored under vendor/assets.
  # See doc/rails_upgrade_plan.md.
  class S3Upload
    ALGORITHM = 'AWS4-HMAC-SHA256'
    SERVICE = 's3'
    TERMINATOR = 'aws4_request'
    POLICY_LIFETIME = 10.hours

    # options: bucket, region, keyStart, acl, accessKey, secretKey
    def self.data_hash(options)
      new(options).data_hash
    end

    def initialize(options)
      @bucket = options[:bucket]
      @region = options[:region]
      @region = 'us-east-1' if @region.nil? || @region == 's3'
      @key_start = options[:keyStart]
      @acl = options[:acl]
      @access_key = options[:accessKey]
      @secret_key = options[:secretKey]
      @date_string = Time.now.strftime('%Y%m%d')
    end

    def data_hash
      encoded_policy = policy
      {
        bucket: @bucket,
        region: @region == 'us-east-1' ? 's3' : "s3-#{@region}",
        keyStart: @key_start,
        params: {
          acl: @acl,
          policy: encoded_policy,
          'x-amz-algorithm': ALGORITHM,
          'x-amz-credential': credential,
          'x-amz-date': amz_date,
          'x-amz-signature': signature(encoded_policy)
        }
      }
    end

    private

    def amz_date
      "#{@date_string}T000000Z"
    end

    def credential
      [@access_key, @date_string, @region, SERVICE, TERMINATOR].join('/')
    end

    def policy
      Base64.strict_encode64(policy_data.to_json)
    end

    def policy_data
      {
        expiration: POLICY_LIFETIME.from_now.utc.iso8601,
        conditions: [
          ['starts-with', '$key', @key_start],
          ['starts-with', '$Content-type', ''],
          { 'x-requested-with': 'xhr' },
          { 'x-amz-algorithm': ALGORITHM },
          { 'x-amz-date': amz_date },
          { 'x-amz-credential': credential },
          { bucket: @bucket },
          { acl: @acl },
          { success_action_status: '201' }
        ]
      }
    end

    def signature(encoded_policy)
      key = ["AWS4#{@secret_key}", @date_string, @region, SERVICE, TERMINATOR]
            .reduce { |memo, part| OpenSSL::HMAC.digest('SHA256', memo, part) }
      OpenSSL::HMAC.hexdigest('SHA256', key, encoded_policy)
    end
  end
end
