class AddAutomaticMessagesToProperties < ActiveRecord::Migration[6.1]
  def up
    # Add SMS message columns
    add_column :properties, :sms_opt_in_request_message, :text
    add_column :properties, :sms_opt_in_confirmation_message, :text
    add_column :properties, :sms_opt_out_confirmation_message, :text

    # Add Email welcome message columns
    add_column :properties, :lead_auto_welcome_email_subject, :string
    add_column :properties, :lead_auto_welcome_email_body, :text

    # Set default messages for EXISTING properties at time of migration
    # (New properties created after this migration will get defaults via the
    # before_create :set_default_messages callback in the Property model)
    execute <<-SQL
      UPDATE properties
      SET sms_opt_in_request_message = 'Thanks for your interest in {{property_name}}! Reply YES to receive text updates about availability and tours. Reply STOP to opt out.',
          sms_opt_in_confirmation_message = 'You''re in! Your dedicated {{property_name}} leasing team is ready to help. Schedule your tour today: {{property_tour_booking_url}}',
          sms_opt_out_confirmation_message = 'You''ve been unsubscribed from {{property_name}} texts. Reply YES anytime to resubscribe.',
          lead_auto_welcome_email_subject = 'Welcome to {{property_name}}!',
          lead_auto_welcome_email_body = '<p>Dear {{lead_first_name}},</p><p>Thank you for your interest in {{property_name}}! We''re thrilled that you''re considering our community as your next home.</p><p>Our team is committed to making your apartment search as smooth and enjoyable as possible. One of our experienced leasing professionals will be reaching out to you shortly to:</p><ul><li>Discuss your specific housing needs and preferences</li><li>Answer any questions about our community and amenities</li><li>Schedule a personalized tour at your convenience</li></ul><p><strong>Ready to see your future home?</strong></p><center style="margin: 20px 0;"><a href="{{property_tour_booking_url}}" style="display: inline-block; padding: 12px 30px; background-color: #007bff; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;">Book a Tour Now</a></center><p><strong>Explore Our Community Online</strong><br>While you wait to hear from us, we invite you to visit <a href="{{property_website}}">{{property_website}}</a> to:</p><ul><li>Browse our available floor plans and pricing</li><li>View our extensive amenities and community features</li><li>Take a virtual tour of our property</li><li>Learn about our neighborhood and local attractions</li></ul><p>If you have any immediate questions, please don''t hesitate to call us at {{property_phone}} or reply to this email.</p><p>We look forward to welcoming you to {{property_name}} and helping you find the perfect place to call home!</p><p>Warm regards,<br>The {{property_name}} Team</p>'
    SQL

    # Set the lead_auto_request_sms_opt_in appsetting to true for EXISTING properties
    # (New properties will get this via the before_create callback)
    Property.find_each do |property|
      property.appsettings ||= {}
      property.appsettings['lead_auto_request_sms_opt_in'] = '1'
      property.save!
    end
  end

  def down
    # Remove the appsetting BEFORE removing columns (to avoid validation errors)
    Property.find_each do |property|
      if property.appsettings && property.appsettings['lead_auto_request_sms_opt_in']
        property.appsettings.delete('lead_auto_request_sms_opt_in')
        # Use update_columns to skip validations since the columns we're validating are about to be removed
        property.update_columns(appsettings: property.appsettings)
      end
    end

    # Remove columns
    remove_column :properties, :sms_opt_in_request_message
    remove_column :properties, :sms_opt_in_confirmation_message
    remove_column :properties, :sms_opt_out_confirmation_message
    remove_column :properties, :lead_auto_welcome_email_subject
    remove_column :properties, :lead_auto_welcome_email_body
  end
end