namespace :health do
  namespace :services do
    desc 'Cloudmailin'
    task cloudmailin: :environment do
      Messages::DeliveryAdapters::Cloudmailin::Health.new(window: 1.hour).call
    end

    desc 'CDR Database'
    task cdr: :environment do
      Cdr.check_replication_status
    end
  end
end
