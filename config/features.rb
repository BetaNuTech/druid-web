require_relative '../app/lib/user_preference_strategy.rb'

Flipflop.configure do
  # Strategies will be used in the order listed here.
  #strategy :cookie
  # strategy :active_record
  strategy UserPreferenceStrategy
  strategy :default

  feature :profile_images_v1, default: true, description: 'Profile image support'

  feature :user_tracking, default: true, description: 'Track page impressions'

  feature :design_v1, default: false, description: 'UI v1 Navigation (Legacy)'
  
  feature :design_v2, default: true, description: 'UI v2 with modern design system'

  lead_automatic_reply_enabled = ['t', 'true', '1'].include? ENV.fetch('LEAD_AUTOMATIC_REPLY','false').downcase
  feature :lead_automatic_reply, default: lead_automatic_reply_enabled, description: 'Automatically respond to incoming leads'
  lead_automatic_dedupe_enabled = ['t', 'true', '1'].include? ENV.fetch('LEAD_AUTOMATIC_DEDUPE','false').downcase
  feature :lead_automatic_dedupe, default: lead_automatic_dedupe_enabled, description: 'Automatically mark high confidence duplicates as invalidated as duplicate'

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
