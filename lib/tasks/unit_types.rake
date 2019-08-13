namespace :unit_types do

  namespace :yardi do

    desc "Import Floorplans"
    task :import_floorplans => :environment do

      properties = Leads::Adapters::YardiVoyager.property_codes

      if ( env_property = ENV.fetch('PROPERTY', nil) ).present?
        property = properties.select{|p| p[:code] == env_property}
        if property.present?
          properties = property
        end
      end

      properties.each do |property|
        # property => { name: 'Property Name', code: 'voyagerpropertyid', property: #<Property> }

        msg = " * Importing Yardi Voyager FloorPlans for #{property[:name]} [YARDI ID: #{property[:code]}] as UnitTypes"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })
        unit_types = adapter.processUnitTypes

        count = unit_types.size
        succeeded = unit_types.select{|l| l.id.present? }.size
        failures = unit_types.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.remoteid}]: #{record.errors.to_a.join(', ')}"
        end

        msg=<<~EOS
          - Processed #{unit_types.size} Records
          - #{succeeded} Records saved
          - #{failures.size} Failed
        EOS
        msg += failures.join("\n")
        puts msg
        Rails.logger.warn msg
      end
    end
  end
end
