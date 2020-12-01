require_relative '../../db/seeds/seed_property_teams.rb'

namespace :db do

  namespace :seed do

    desc "Seed Property Data"
    task :properties => :environment do
      require_relative Rails.root + "db/seeds/seed_properties"

      SeedProperties.new.call
    end

    namespace :property do
      desc "Seed Property Timezones"
      task :timezones => :environment do
        filename = Rails.root + 'db/seeds/property_timezones.yml'
        data = YAML.load(File.read(filename))
        data.each do |p|
          name = p[:name]
          tz = p[:timezone]
          property = Property.find_by_name(name)
          puts "  - #{name} => #{tz}"
          property.timezone = tz
          property.save!
        end
      end
    end


    desc "Seed LeadActions"
    task :lead_actions => :environment do
      LeadAction.load_seed_data
    end

    desc "Seed Reasons"
    task :reasons => :environment do
      Reason.load_seed_data
    end

    desc "Seed Teams"
    task :teams => :environment do

      Team.load_seed_data
      SeedPropertyTeams.load_seed_data
    end

    desc "Seed Articles"
    task :articles => :environment do
      Article.load_seed_data
    end

    desc "Seed LeadSources"
    task :lead_sources => :environment do
      LeadSource.load_seed_data
    end

    desc "Bluesky Portal Listings"
    task :bluesky_portal_listings => :environment do
      puts "== Creating Bluesky Portal Listings"

      lead_source = LeadSource.where(slug: 'BlueskyPortal').first
      unless lead_source.present?
        puts "  ! BlueSkyPortal LeadSource not found! Aborting!"
        return false
      end
      Property.active.each do |property|
        code = Leads::Adapters::YardiVoyager.property_code(property) rescue nil
        if code.present?
          listing = PropertyListing.new(
            property_id: property.id,
            source_id: lead_source.id,
            code: code,
            active: true
          )
          if listing.save
            puts "  + Created PropertyListing '#{code}' for #{property.name} on #{lead_source.name}"
          else
            puts "  ! Error creating PropertyListing {code: '#{code}', source: '#{lead_source.name}'} for #{property.name}: #{listing.errors.to_a}"
          end
        else
          puts "  ! #{propery.name} has no Voyager code! Skipping Bluesky Portal listing"
        end
      end
      puts "DONE.\n"
    end

    desc "Seed Development Environment with random data"
    task :development => :environment do
      require 'factory_bot_rails'

      puts "=== Seeding Development Environment"

      puts "(press ENTER to continue or CTRL-C to quit)"
      _c = STDIN.gets

      team_count = 5
      puts "= Creating #{team_count} Teams"
      team_count.times do
        team = FactoryBot.create(:team)
        puts " - #{team.name}"
        Property.all.each do |property|
          property.team = Team.order("RANDOM()").first
          property.save
        end
      end

      agent_count = 10
      puts "= Creating #{agent_count} Agents"
      agent_count.times {
        role = Role.where("slug != 'administrator'").order("RANDOM()").first
        user = FactoryBot.create(:user, role: role)
        team = Team.order("RANDOM()").first
        teamrole = Teamrole.order("RANDOM()").first
        puts "  - #{user.name} is a member of #{team.name}"
        TeamUser.create(user: user, team: team, teamrole: teamrole)
      }

      lead_count = 200
      puts "= Creating #{lead_count } Leads"
      lead_count.times {
        agent = TeamUser.order("RANDOM()").first.user
        property = agent.team.properties.order("RANDOM()").first
        lead_source = LeadSource.order("RANDOM()").first
        lead = FactoryBot.create(:lead, property: property, source: lead_source, referral: lead_source.name)
        puts "  - #{lead.name}: interested in the property #{property.name}"
        if (Faker::Boolean.boolean(true_ratio: 0.2))
          lead.user = agent
          lead.claim if lead.open?
          puts "    + Claimed by #{agent.name}"
        end
      }

    end

    desc "Random Articles"
    task :random_articles => :environment do
      require 'factory_bot_rails'

      puts "= Creating dummy News Articles"
      10.times do
        FactoryBot.create(:article,
                          articletype: 'news',
                          category: 'General',
                          contextid: 'Home#')
      end

      puts "= Creating dummy Blog Articles"
      10.times do
        FactoryBot.create(:article,
                          articletype: 'blog',
                          category: 'general',
                          contextid: 'Home#')
      end

      puts "= Creating dummy Help Articles"
      10.times do
        FactoryBot.create(:article,
                          articletype: 'help',
                          user: User.order("random() asc").first,
                          category: 'general',
                          contextid: AppContext.list.sample)
      end

      puts "= Creating dummy Tooltips"
      10.times do
        FactoryBot.create(:article,
                          articletype: 'tooltip',
                          category: 'general',
                          contextid: AppContext.list.sample)
      end
    end

    desc "Load EngagementPolicy"
    task :engagement_policy => :environment do
      filename = File.join(Rails.root,"db","seeds", "engagement_policy.yml")

      puts "*** Loading EngagementPolicy from #{filename}"
      loader = EngagementPolicyLoader.new(filename)
      loader.call
    end

    desc "Load Message Types"
    task :message_types => :environment do
      MessageType.load_seed_data
    end

    desc "Load Message Templates"
    task :message_templates => :environment do
      MessageTemplate.load_seed_data
    end

    desc "Load Message Delivery Adapters"
    task :message_delivery_adapters => :environment do
      MessageDeliveryAdapter.load_seed_data
    end

    desc "Load Lead Referral Sources"
    task :lead_referral_sources => :environment do
      LeadReferralSource.load_seed_data
    end

  end # namespace :seed

end # namespace :db
