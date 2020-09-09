module UserProfiles
  module Features
    extend ActiveSupport::Concern

    included do

      FEATURE_PARAMS = { enabled_features: UserProfile.managed_features }

      serialize :enabled_features

      def feature_enabled?(feature)
        val = enabled_features.fetch(feature, false)
        [true, 'true', '1'].include?(val)
      end

      def switch_feature!(feature, enabled)
        val = [true, 'true', '1'].include?(enabled) ? '1' : '0'
        enabled_features[feature] = val
        save!
      end

      def clear_feature!(feature)
        enabled_features.delete(feature)
        save!
      end
    end

    class_methods do
      def managed_features
        Flipflop.feature_set.features.map { |f| f.name.to_sym}
      end
    end
  end
end
