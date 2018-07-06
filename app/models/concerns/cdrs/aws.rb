module Cdrs
  module Aws
    extend ActiveSupport::Concern

    included do

      def recording_bucket_name
        ::CDRDB_CALL_RECORDING_S3_CONFIG[:bucket]
      end

      def recording_path_key
        return calldate.strftime("%Y/%m/%d/#{recordingfile}")
      end

      def recording_path
        # see config/initializers/aws.rb for AWS S3 client configuration

        @cached_recording_path ||= (
          object_info = ::CDRDB_CALL_RECORDING_S3_CLIENT.head_object(
            bucket: recording_bucket_name,
            key: recording_path_key
          ) rescue nil

          object_info.nil? ?
              nil :
              ::CDRDB_CALL_RECORDING_S3_SIGNER.presigned_url(
                :get_object,
                bucket: ::CDRDB_CALL_RECORDING_S3_CONFIG[:bucket],
                key: recording_path_key
              )
        )

        return @cached_recording_path
      end

      def recording_present?
        return !recording_path.nil?
      end

    end
  end
end

