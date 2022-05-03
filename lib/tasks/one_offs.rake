namespace :oneoff do
  desc 'Deactivate Users'
  task :deactivate_users => :environment do
    service = Users::MassDeactivator.new
    service.call
  end

  desc 'Undo Deactivate Users'
  task :undo_deactivate_users => :environment do
    service = Users::MassDeactivator.new
    service.undo
  end
end
