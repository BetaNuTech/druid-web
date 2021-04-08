module UserProfiles
  module Features
    extend ActiveSupport::Concern

    included do

      FEATURE_PARAMS = { enabled_features: UserProfile.managed_features }

      serialize :enabled_features

      def feature_enabled?(feature)
        self.enabled_features ||= {}
        val = enabled_features.fetch(feature.to_s, nil)
        return nil if val.nil?

        [true, 'true', '1'].include?(val)
      end

      def switch_feature!(feature, enabled)
        val = [true, 'true', '1'].include?(enabled) ? '1' : '0'
        enabled_features[feature.to_s] = val
        save!
      end

      def clear_feature!(feature)
        self.enabled_features ||= {}
        enabled_features.delete(feature.to_s)
        save!
      end
    end

    class_methods do
      def managed_features
        Flipflop.feature_set.features.map { |f| f.name.to_sym }
      end

      def default_features
        managed_features.inject({}) do |memo, obj|
          memo[obj.to_s] = '1'
          memo
        end
      end
    end
  end
end
