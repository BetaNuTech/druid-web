module UserProfiles
  module Appsettings
    extend ActiveSupport::Concern

    included do

      APPSETTING_PARAMS = { appsettings: UserProfile.managed_settings }

      serialize :appsettings

      def setting_enabled?(setting)
        val = appsettings.fetch(setting, false)
        [true, 'true', '1'].include?(val)
      end

      def switch_setting!(setting, enabled)
        val = [true, 'true', '1'].include?(enabled) ? '1' : '0'
        appsettings[setting] = val
        save!
      end

      def clear_setting!(setting)
        appsettings.delete(setting)
        save!
      end

      def monitor_all_messages?
        setting_enabled?(:view_all_messages)
      end
    end

    class_methods do
      def managed_settings
        [:message_signature, :view_all_messages, :message_web_notifications, :lead_web_notifications]
      end
    end
  end
end
