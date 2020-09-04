class AddEnabledFeaturesToUserProfile < ActiveRecord::Migration[6.0]
  def change
    add_column :user_profiles, :enabled_features, :jsonb, default: {}
  end
end
