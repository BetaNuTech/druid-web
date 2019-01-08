namespace :cache do


  namespace :warm do

    desc "Warm All Caches"
    task :all => [:prospect_stats] do
      # NOOP
      Rails.logger.info "=== Caches are Warm"
    end

    desc "Warm PospectStats cache"
    task :prospect_stats => :environment do
      stats = ProspectStats.new
      stats.caching = true
      Rails.logger.warn "=== Warming ProspectStats cache"
      stats.refresh_cache
    end
  end
end
