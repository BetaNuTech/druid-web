namespace :users do

  desc 'Report Pageviews'
  task report: :environment do

  end

  desc 'Send User Task Notification Reminders'
  task task_reminders: :environment do
    # Email pending task notifications to Active Users
    User.send_pending_task_notifications
  end
end
