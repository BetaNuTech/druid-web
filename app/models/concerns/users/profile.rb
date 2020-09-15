module Users
  module Profile
    extend ActiveSupport::Concern

    included do
      after_initialize do
        build_profile unless profile.present?
      end

      has_one :profile, class_name: 'UserProfile', dependent: :destroy, required: false
      accepts_nested_attributes_for :profile

      delegate :name_prefix, to: :profile, allow_nil: true
      delegate :first_name, to: :profile, allow_nil: true
      delegate :last_name, to: :profile, allow_nil: true
      delegate :office_phone, to: :profile, allow_nil: true
      delegate :cell_phone, to: :profile, allow_nil: true
      delegate :fax, to: :profile, allow_nil: true
      delegate :notes, to: :profile, allow_nil: true
      delegate :use_signature?, to: :profile, allow_nil: true
      delegate :monitor_all_messages?, to: :profile, allow_nil: true
      delegate :enabled_features, to: :profile, allow_nil: true
      delegate :feature_enabled?, to: :profile, allow_nil: true
      delegate :switch_feature!, to: :profile, allow_nil: true
      delegate :clear_feature!, to: :profile, allow_nil: true
      delegate :appsettings, to: :profile, allow_nil: true
      delegate :setting_enabled?, to: :profile, allow_nil: true
      delegate :switch_setting!, to: :profile, allow_nil: true
      delegate :clear_setting!, to: :profile, allow_nil: true
    end
  end
end
