class SeedPropertyTeams

  def initialize(filename=nil)
    @file = filename || ( File.dirname(__FILE__) + '/property_teams.yml' )
    raise "#{@file} not FOUND" unless File.exist?(@file)
  end

  def call
    puts "*** SEED LOAD: Property Team assignments"

    data = YAML.load(File.read @file)
    all_property_codes = Leads::Adapters::YardiVoyager.property_codes
    Team.transaction do
      data.each do |team_config|
        team_name = team_config[:name]
        team = Team.where(name: team_name).first
        raise "Team #{team_name} not found! Aborting" unless team.present?

        team_property_codes = team_config[:properties]

        matched_properties = []
        not_found = []

        team_property_codes.each do |code|
          matched_property = all_property_codes.find{|pc| pc[:code] == code}
          if matched_property
            matched_properties << matched_property[:property]
          else
            not_found << code
          end
        end

        raise "Could not find Property matching code(s): #{not_found}" if not_found.any?

        puts " * Assigned Properties to Team #{team.name}:"
        matched_properties.each do |property|
          property.team_id = team.id
          property.save || raise("Error saving Property[#{property.id}] #{property.name}: #{property.errors.to_a}")
          puts "   - #{property.name}"
        end

      end
    end
    return true
  rescue => e
    puts "*** An error occurred. #{e} \n\n***Rolling back all changes.\n\n"
    return false
  end

  def self.load_seed_data
    SeedPropertyTeams.new.call
  end
end
