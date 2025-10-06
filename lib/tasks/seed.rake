require_relative '../../db/seeds/seed_property_teams.rb'
require 'faker'

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
          property = Property.where(name: name).first
          next unless property.present?
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
          lead.work if lead.open?
          puts "    + Worked by #{agent.name}"
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

    desc "Create Sample Referral Bounces (dev only)"
    task :referral_bounces => :environment do
      if Rails.env.production?
        puts "Refusing to create test data in production!"
        return true
      end


      record_count = 50
      campaigns = Array.new(5) do
        random_string = "C-" + ('A'..'Z').to_a.sample(6).join
        url = Faker::Internet.url
        [random_string, url]
      end
      properties = Property.active.all.map{|f| [f, f.name[0..4].downcase]}

      puts "*** Creating sample Referral Bounce Records (#{record_count} per property)"

      properties.each do |property|
        puts "* #{property.first.name} "
        bar = TTY::ProgressBar.new('[:bar]', total: record_count)
        record_count.times do
          campaign = campaigns.sample(1).first
          bounce = FactoryBot.create(:referral_bounce,
                                     property: property.first,
                                     propertycode: property.last,
                                     campaignid: campaign.first,
                                     referer: campaign.last,
                                     trackingid: 'T-' + SecureRandom.hex(10).upcase
                                    )
          new_timestamp = Time.current - rand(15_000_000)
          bounce.updated_at = bounce.created_at = new_timestamp
          bounce.update_columns(created_at: new_timestamp, updated_at: new_timestamp)
          bar.advance
        end
        puts
      end
      puts "DONE."
    end

  end # namespace :seed

end # namespace :db
