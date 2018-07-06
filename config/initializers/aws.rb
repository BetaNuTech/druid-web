if Rails.env.test?
  Rails.logger.warn "CDRDB S3 configuration skipped in TEST"
else

  ### BEGIN CDRDB Call Recording Configuration
  config = {
    region: 'CDRDB_S3_REGION',
    bucket: 'CDRDB_S3_BUCKET',
    access_key: 'CDRDB_S3_ACCESS_KEY',
    secret_key: 'CDRDB_S3_SECRET_KEY',
  }

  error_messages = []

  ::CDRDB_CALL_RECORDING_S3_CONFIG = {
    region: ENV.fetch(config[:region], nil),
    bucket: ENV.fetch(config[:bucket], nil),
    access_key: ENV.fetch(config[:access_key], nil),
    secret_key: ENV.fetch(config[:secret_key], nil)
  }

  CDRDB_CALL_RECORDING_S3_CONFIG.each_pair do |key,value|
    if value.nil?
      msg = "ERROR: CDR call data configuration. Missing environment variable: #{config[key]}"
      error_messages << msg
      Rails.logger.error msg
    end
  end

  if error_messages.empty?
    ::CDRDB_CALL_RECORDING_S3_CLIENT = Aws::S3::Client.new(
      region:               CDRDB_CALL_RECORDING_S3_CONFIG[:region],
      access_key_id:        CDRDB_CALL_RECORDING_S3_CONFIG[:access_key],
      secret_access_key:    CDRDB_CALL_RECORDING_S3_CONFIG[:secret_key]
    )
    ::CDRDB_CALL_RECORDING_S3_SIGNER = Aws::S3::Presigner.new(client: CDRDB_CALL_RECORDING_S3_CLIENT)
  end
  ### END CDRDB Call Recording Configuration

end
