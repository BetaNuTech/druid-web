module UserProfiles
  module Appsettings
    extend ActiveSupport::Concern

    MANAGED_SETTINGS = %w[
      message_signature
      view_all_messages
      message_web_notifications
      lead_web_notifications
      email_task_reminders
      select_task_reason
    ].freeze

    included do

      APPSETTING_PARAMS = { appsettings: UserProfile.managed_settings }

      serialize :appsettings

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

      def monitor_all_messages?
        self.appsettings ||= {}
        setting_enabled?(:view_all_messages)
      end

      def repair_settings!
        old_settings = appsettings
        self.appsettings = {}
        MANAGED_SETTINGS.each do |setting|
          self.appsettings[setting] = old_settings.fetch(setting, nil) || old_settings.fetch(setting.to_s, '1')
        end
        save!
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
