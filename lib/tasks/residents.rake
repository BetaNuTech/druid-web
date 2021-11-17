namespace :residents do
  namespace :yardi do
    desc "Import Residents"
    task import: :environment do
      msg = '* Creating/updating residents from Voyager'
      puts msg; Rails.logger.warn msg

      properties = Leads::Adapters::YardiVoyager.property_codes

      if ( env_property = ENV.fetch('PROPERTY', nil) ).present?
        property = properties.select{|p| p[:code] == env_property}
        if property.present?
          properties = property
        end
      end

      properties.each do |property|
        msg = " * Importing Yardi Voyager Residents for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg; Rails.logger.warn msg

        adapter = Leads::Adapters::YardiVoyager.new(property[:property])
        msg = " * Processing Residents for #{property[:name]} [YARDI ID: #{property[:code]}]"
        puts msg
        Rails.logger.warn msg
        residents = adapter.processResidents(start_date: nil, end_date: DateTime.now)

        resident_count = residents.size
        resident_succeeded = residents.select{|l| l.id.present? }.size
        resident_failures = residents.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.name} [Yardi ID: #{record.residentid}]: #{record.errors.to_a.join(', ')}"
        end
        msg=<<~EOS
        - Processed #{residents.size} Resident Records
        --- #{resident_succeeded} Resident Records saved
        --- #{resident_failures.size} Failed
        --- #{resident_failures.join("\n ---")}
        EOS
        puts msg; Rails.logger.warn msg
      end

    end
  end
end
