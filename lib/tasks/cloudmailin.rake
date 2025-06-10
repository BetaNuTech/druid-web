namespace :cloudmailin do
  desc "Retry failed CloudMailin emails"
  task retry_failed: :environment do
    failed_emails = CloudmailinRawEmail.retryable
    
    puts "Found #{failed_emails.count} failed emails to retry"
    
    failed_emails.find_each do |raw_email|
      puts "Retrying email #{raw_email.id} (attempt #{raw_email.retry_count + 1})"
      raw_email.update!(status: 'pending')
      ProcessCloudmailinEmailJob.perform_later(raw_email)
    end
    
    puts "Queued #{failed_emails.count} emails for retry"
  end
  
  desc "Process pending CloudMailin emails"
  task process_pending: :environment do
    pending_emails = CloudmailinRawEmail.pending
    
    puts "Found #{pending_emails.count} pending emails"
    
    pending_emails.find_each do |raw_email|
      ProcessCloudmailinEmailJob.perform_later(raw_email)
    end
    
    puts "Queued #{pending_emails.count} emails for processing"
  end
  
  desc "Clean up old processed CloudMailin emails"
  task cleanup: :environment do
    older_than = 30.days.ago
    old_emails = CloudmailinRawEmail.where(status: 'completed').where('created_at < ?', older_than)
    
    count = old_emails.count
    old_emails.destroy_all
    
    puts "Deleted #{count} processed emails older than #{older_than}"
  end
  
  desc "Show CloudMailin email statistics"
  task stats: :environment do
    total = CloudmailinRawEmail.count
    by_status = CloudmailinRawEmail.group(:status).count
    
    puts "\nCloudMailin Email Statistics:"
    puts "Total emails: #{total}"
    puts "\nBy Status:"
    by_status.each do |status, count|
      puts "  #{status}: #{count}"
    end
    
    if CloudmailinRawEmail.failed.any?
      puts "\nRecent failures:"
      CloudmailinRawEmail.failed.order(created_at: :desc).limit(5).each do |email|
        puts "  ID: #{email.id}"
        puts "  Property: #{email.property_code}"
        puts "  Error: #{email.error_message}"
        puts "  Created: #{email.created_at}"
        puts "  ---"
      end
    end
  end
end