module Properties
  module Appsettings
    extend ActiveSupport::Concern

    MANAGED_SETTINGS = %w[
      lead_company_information
      lead_auto_welcome
      lead_auto_request_sms_opt_in
      lea_ai_handling
    ].freeze

    included do

      APPSETTING_PARAMS = { appsettings: Property.managed_settings }

      serialize :appsettings

      ### Helper methods

      def lead_auto_welcome?
        setting_enabled?(:lead_auto_welcome)
      end

      def lead_auto_request_sms_opt_in?
        setting_enabled?(:lead_auto_request_sms_opt_in)
      end

      def lea_ai_handling?
        setting_enabled?(:lea_ai_handling)
      end


      ### Core Logic

      def setting_enabled?(setting)
        key = setting.to_s
        self.appsettings ||= {}
        val = appsettings.fetch(key, false)
        [true, 'true', '1'].include?(val)
      end

      def switch_setting!(setting, enabled)
        key = setting.to_s
        self.appsettings ||= {}
        val = [true, 'true', '1'].include?(enabled) ? '1' : '0'
        appsettings[key] = val
        save!
      end

      def clear_setting!(setting)
        key = setting.to_s
        self.appsettings ||= {}
        appsettings.delete(key)
        save!
      end

      def repair_settings!
        old_settings = appsettings
        self.appsettings = {}
        MANAGED_SETTINGS.each do |setting|
          self.appsettings[setting] = old_settings.fetch(setting, nil) || old_settings.fetch(setting.to_s, '0')
        end
        save!
      end

      def appsettings_with_missing
        Property.negative_default_settings.merge(appsettings)
      end



    end

    class_methods do
      def managed_settings
        MANAGED_SETTINGS
      end
      
      def default_settings
        managed_settings.inject({}) do |memo, obj|
          memo[obj] = '1'
          memo
        end
      end

      def negative_default_settings
        managed_settings.inject({}) do |memo, obj|
          memo[obj] = '0'
          memo
        end
      end
    end
  end
end
