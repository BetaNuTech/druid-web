namespace :units do
  namespace :yardi do
    desc "Import Units"
    task :import_units => :environment do

      properties = [
        {name: 'Maplebrook', code: 'maplebr'},
        {name: 'Marble Alley', code: 'marble'},
      ]

      properties.each do |property|
        msg = " * Importing Yardi Voyager Units for #{property[:name]} [YARDI ID: #{property[:code]}] as Units"
        puts msg
        Rails.logger.warn msg
        adapter = Leads::Adapters::YardiVoyager.new({ property_code: property[:code] })
        units = adapter.processUnits

        count = units.size
        succeeded = units.select{|l| l.id.present? }.size
        failures = units.select{|l| !l.errors.empty?}.map do |record|
          "FAIL: #{record.unit} [Yardi ID: #{record.remoteid}]: #{record.errors.to_a.join(', ')}"
        end

        msg=<<~EOS
        - Processed #{units.size} Records
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
