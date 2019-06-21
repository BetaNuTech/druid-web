namespace :messages do

  desc "Set Missing Incoming Flag on all Messages"
  task :set_missing_incoming_flag => :environment do
    puts "= Setting missing Message incoming flags"
    Message.where(incoming: nil).find_in_batches.each do |message_group|
      message_group.each do |message|
        message.set_missing_incoming_flag
        message.save
        print "."
      end
    end
    puts "\n= Done"
  end

  desc "Set Missing since_last"
  task :set_missing_since_last => :environment do
    puts "= Setting missing Message since_last data"
    Message.where(since_last: nil).find_in_batches.each do |message_group|
      message_group.each do |message|
        message.set_time_since_last_message
        message.save
        print "."
      end
    end
    puts "\n= Done"
  end
end
