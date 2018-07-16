module Cdrs
  module Aws
    extend ActiveSupport::Concern

    included do

      def recording_bucket_name
        ::CDRDB_CALL_RECORDING_S3_CONFIG[:bucket]
      end

      def recording_path_key
        return recordingfile.present? ? calldate.strftime("%Y/%m/%d/#{recordingfile}") : nil
      end

      def recording_path
        # see config/initializers/aws.rb for AWS S3 client configuration

        @cached_recording_path ||= (
          if recording_path_key
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
          else
            nil
          end
        )

        return @cached_recording_path
      end

      def recording_present?
        return !recording_path.nil?
      end

      def recording_media_type
        extension = ( recording_path || '').split('.').last
        return case extension
        when'wav'
          'audio/wav'
        when 'mp3'
          'audio/mpeg'
        else
          ''
        end
      end

    end
  end
end

