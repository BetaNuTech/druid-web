module Yardi
  module Voyager
    module Api
      class Configuration
        ENV_PREFIX = 'YARDI_VOYAGER'
        DEFAULT_PLATFORM='SQL Server'
        PROPERTIES = [ :username, :password, :servername, :host, :webshare, :platform, :database, :vendorname, :license ]

        attr_reader *PROPERTIES
        attr_reader :errors

        # Initialize using ENVVARS or with a provided Hash with keys matching PROPERTIES
        def initialize(source=:env)
          @errors = []
          case source
          when :env
            load_env_settings
          when Hash
            load_hash_settings(source)
          end
          @valid, @errors = validate_settings
          @valid
        end

        def to_h
          PROPERTIES.inject({}){|memo, obj| memo[obj] = self.send(obj); memo }
        end

        def valid?
          @valid
        end

        private

        def load_hash_settings(data)
          @errors = []
          @username = data.fetch(:username, nil)
          @password = data.fetch(:password, nil)
          @servername = data.fetch(:servername, nil)
          @host = data.fetch(:host, nil)
          @webshare = data.fetch(:webshare, nil)
          @platform = DEFAULT_PLATFORM
          @database = data.fetch(:database, nil)
          @vendorname = data.fetch(:vendorname, nil)
          @license = data.fetch(:license, nil)
        end

        def load_env_settings
          @errors = []
          @username = get_prefixed_env(:username)
          @password = get_prefixed_env(:password)
          @servername = get_prefixed_env(:servername)
          @host = get_prefixed_env(:host)
          @webshare = get_prefixed_env(:webshare)
          @platform = DEFAULT_PLATFORM
          @database = get_prefixed_env(:database)
          @vendorname = get_prefixed_env(:vendorname)
          @license = get_prefixed_env(:license)
        end

        def get_prefixed_env(var)
          val = ENV.fetch("#{ENV_PREFIX}_#{var.to_s.upcase}", nil)
          return val
        end

        # Returns Array: [isValid, errorsArr]
        def validate_settings
          errors = []
          PROPERTIES.each do |prop|
            if !( defined?(prop) && self.send(prop).present? )
              errors << "Missing: #{prop.to_s}"
            end
          end
          return [errors.empty?, errors]
        end
      end
    end
  end
end
