namespace :residents do
  namespace :yardi do

    desc "Import/Update Residents"
    task import: :environment do
      msg = '*** Creating/updating residents from Yardi Voyager'
      puts msg; Rails.logger.warn msg
      env_property = ENV.fetch('PROPERTY', nil) 
      properties = env_property ? [env_property] : []

      Residents::Adapters::YardiVoyager.sync(properties, true)
    end

  end
end
