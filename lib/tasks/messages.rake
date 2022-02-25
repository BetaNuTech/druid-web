namespace :messages do

  desc 'Retry Delivery'
  task retry: :environment do
    start_time = 2.days.ago
    puts "*** Retrying failed delivery of #{Message.pending_retry(start_time: start_time).count} outgoing messages"
    Message.retry_deliveries(start_time: start_time)
  end

  desc "Fix Disqualified Lead Messages"
  task :fix_notifications => :environment do
    skope = Message.joins("inner join leads on messages.messageable_id = leads.id").where(leads: {state: 'disqualified'}, messages: {read_at: nil})
    Message.mark_read!(skope)
  end

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

  desc 'Dummy Incoming Message'
  task :dummy_incoming_message, [:lead] => :environment do |t, args|
    lead_id = args[:lead]
    raise 'Provide Lead id: rake messages:dummy_incoming_message[LEADID]' unless lead_id.present?
    lead = Lead.find(lead_id)

    message = Message.new(
      messageable:  lead,
      user_id: lead.user_id,
      state: 'sent',
      message_template_id: nil,
      message_type_id: MessageType.email.id,
      subject: Faker::Lorem.sentence,
      body: Faker::Lorem.paragraph,
      incoming: true
    )
    message.recipientid = message.incoming_recipientid
    message.senderid = message.incoming_senderid
    message.save!

    delivery = MessageDelivery.create(
      message: message,
      message_type: message.message_type,
      attempt: 1,
      attempted_at: message.delivered_at,
      status: MessageDelivery::SUCCESS,
      delivered_at: message.delivered_at
    )
    message.handle_message_delivery(delivery)

    puts "=== Sent dummy message to Lead #{lead.name} (#{lead.id})"
  end

end
