require_relative '../app/lib/user_preference_strategy.rb'

Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy UserPreferenceStrategy
  #strategy :cookie
  strategy :active_record
  strategy :default

  feature :profile_images_v1, default: false, description: 'Profile image support'

  group :design_v1 do
    feature :navigation_v1, default: false, description: 'UI v1 Navigation'
    feature :leads_v1, default: false, description: 'UI v1 Lead Page'
    feature :lead_search_v1, default: false, description: 'UI v1 Lead Search Page'
  end

  # Other strategies:
  #
  # strategy :sequel
  # strategy :redis
  #
  # strategy :query_string
  # strategy :session
  #
  # strategy :my_strategy do |feature|
  #   # ... your custom code here; return true/false/nil.
  # end

  # Declare your features, e.g:
  #
  # feature :world_domination,
  #   default: true,
  #   description: "Take over the world."
end
