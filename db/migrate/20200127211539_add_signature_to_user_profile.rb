class AddSignatureToUserProfile < ActiveRecord::Migration[6.0]
  def change
    add_column :user_profiles, :signature, :text
    add_column :user_profiles, :signature_enabled, :boolean, default: false
  end
end
