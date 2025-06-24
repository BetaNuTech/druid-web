namespace :users do
  desc "Migrate all users to design v2"
  task migrate_to_v2: :environment do
    total_users = User.count
    updated_count = 0
    skipped_count = 0
    
    puts "Starting migration of #{total_users} users to design v2..."
    puts "=" * 50
    
    User.includes(:profile).find_each.with_index do |user, index|
      begin
        # Check if user already has v2 enabled
        if user.feature_enabled?(:design_v2)
          skipped_count += 1
          print "."
        else
          # Enable v2 and disable v1 for the user
          user.switch_feature!(:design_v2, true)
          user.switch_feature!(:design_v1, false)
          updated_count += 1
          print "+"
        end
        
        # Progress indicator every 50 users
        if (index + 1) % 50 == 0
          puts " #{index + 1}/#{total_users}"
        end
      rescue => e
        puts "\nError updating user #{user.id}: #{e.message}"
      end
    end
    
    puts "\n" + "=" * 50
    puts "Migration completed!"
    puts "Users updated: #{updated_count}"
    puts "Users already on v2: #{skipped_count}"
    puts "Total users processed: #{updated_count + skipped_count}"
  end
  
  desc "Report on design version usage"
  task design_version_report: :environment do
    total_users = User.count
    v1_users = 0
    v2_users = 0
    default_users = 0
    
    User.includes(:profile).find_each do |user|
      if user.profile&.enabled_features&.key?('design_v2')
        if user.feature_enabled?(:design_v2)
          v2_users += 1
        else
          v1_users += 1
        end
      else
        default_users += 1
      end
    end
    
    puts "Design Version Report"
    puts "=" * 30
    puts "Total users: #{total_users}"
    puts "Using v2: #{v2_users}"
    puts "Using v1: #{v1_users}"
    puts "Using default: #{default_users}"
    puts "=" * 30
  end
  
  desc "Rollback users to design v1 (emergency use only)"
  task rollback_to_v1: :environment do
    print "Are you sure you want to rollback all users to v1? (yes/no): "
    response = STDIN.gets.chomp.downcase
    
    unless response == 'yes'
      puts "Rollback cancelled."
      exit
    end
    
    updated_count = 0
    
    User.includes(:profile).find_each do |user|
      if user.feature_enabled?(:design_v2)
        user.switch_feature!(:design_v1, true)
        user.switch_feature!(:design_v2, false)
        updated_count += 1
      end
    end
    
    puts "Rolled back #{updated_count} users to design v1."
  end
end