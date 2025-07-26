class CreateBlueskySystemUser < ActiveRecord::Migration[6.1]
  def up
    # Find or create administrator role
    admin_role = Role.find_by(name: 'Administrator')
    
    # Find or create system user
    system_user = User.find_or_initialize_by(email: 'system@bluesky.internal')
    
    if system_user.new_record?
      attributes = {
        password: SecureRandom.hex(32),
        role: admin_role,
        confirmed_at: Time.current
      }
      # Only set system_user if column exists
      attributes[:system_user] = true if User.column_names.include?('system_user')
      
      system_user.assign_attributes(attributes)
      system_user.save!
    else
      # Only update system_user if column exists
      if User.column_names.include?('system_user')
        system_user.update!(system_user: true)
      end
    end
    
    # Create or update user profile with just first name
    if system_user.profile.nil?
      system_user.create_profile!(
        first_name: 'Bluesky',
        last_name: nil
      )
    else
      system_user.profile.update!(
        first_name: 'Bluesky',
        last_name: nil
      )
    end
  end
  
  def down
    User.find_by(email: 'system@bluesky.internal')&.destroy
  end
end