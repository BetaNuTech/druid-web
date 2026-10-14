namespace :residents do
  namespace :yardi do

    desc "Import/Update Residents from the Yardi backup database (falls back to the Voyager SOAP API when the backup is not configured; supports PROPERTY=1002edge and DRY_RUN=true)"
    task import: :environment do
      env_property = ENV.fetch('PROPERTY', nil)
      properties = env_property ? [env_property] : []
      dry_run = ENV.fetch('DRY_RUN', 'false') == 'true'

      if Yardi::Backup::Database.configured?
        msg = "*** Creating/updating residents from the Yardi backup database#{' (DRY RUN)' if dry_run}"
        puts msg; Rails.logger.warn msg
        Residents::Adapters::YardiBackup.sync(properties, true, dry_run: dry_run)
      else
        abort '! DRY_RUN is only supported with the Yardi backup database (YARDI_BACKUP_DB_* not set)' if dry_run
        msg = '*** Creating/updating residents from Yardi Voyager (SOAP; Yardi backup database not configured)'
        puts msg; Rails.logger.warn msg
        Residents::Adapters::YardiVoyager.sync(properties, true)
      end
    end

  end
end
