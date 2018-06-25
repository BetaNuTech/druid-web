namespace :unit_types do

  namespace :yardi do

    desc "Import GuestCards"
    task :import_floorplans => :environment do

      properties = [
        {name: 'Maplebrook', code: 'maplebr'},
        {name: 'Marble Alley', code: 'marble'},
      ]

      properties.each do |property|
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
