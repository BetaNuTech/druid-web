module UserProfiles
  module Appsettings
    extend ActiveSupport::Concern

    MANAGED_SETTINGS = %i[
      message_signature
      view_all_messages
      message_web_notifications
      lead_web_notifications
      email_task_reminders
    ].freeze

    included do

      APPSETTING_PARAMS = { appsettings: UserProfile.managed_settings }

      serialize :appsettings

      def setting_enabled?(setting)
        self.appsettings ||= {}
        val = appsettings.fetch(setting, false)
        [true, 'true', '1'].include?(val)
      end

      def switch_setting!(setting, enabled)
        self.appsettings ||= {}
        val = [true, 'true', '1'].include?(enabled) ? '1' : '0'
        appsettings[setting] = val
        save!
      end

      def clear_setting!(setting)
        self.appsettings ||= {}
        appsettings.delete(setting)
        save!
      end

      def monitor_all_messages?
        self.appsettings ||= {}
        setting_enabled?(:view_all_messages)
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
    end
  end
end
