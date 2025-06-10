class ProcessCloudmailinEmailJob < ApplicationJob
  queue_as :default
  
  retry_on OpenaiClient::RateLimitError, wait: 1.minute, attempts: 3
  retry_on OpenaiClient::ServiceUnavailableError, wait: 5.minutes, attempts: 2
  
  def perform(raw_email)
    return if raw_email.status == 'completed'
    
    raw_email.update!(status: 'processing')
    
    # Extract property from email
    property_code = raw_email.property_code
    property = find_property(property_code)
    
    if property.nil? || !property.active?
      handle_inactive_property(raw_email, property_code)
      return
    end
    
    # Get active lead sources for this property
    active_sources = property.listings.active.includes(:source).map(&:source)
    
    # Analyze email with OpenAI
    openai_client = OpenaiClient.new
    analysis = openai_client.analyze_email(raw_email.raw_data, property, active_sources)
    
    if analysis.nil?
      handle_openai_failure(raw_email)
      return
    end
    
    raw_email.update!(
      openai_response: analysis,
      openai_confidence_score: analysis['confidence']
    )
    
    # Create lead based on analysis
    create_lead_from_analysis(raw_email, analysis, property)
    
  rescue => e
    handle_error(raw_email, e)
    raise # Re-raise for retry logic
  end
  
  private
  
  def find_property(property_code)
    # First check if it's a direct property ID
    property = Property.active.find_by(id: property_code)
    return property if property
    
    # Then check property listings
    source = LeadSource.find_by(slug: 'Cloudmailin')
    return nil unless source
    
    listing = PropertyListing.active
      .joins(:property)
      .where(source: source, code: property_code)
      .where(properties: { active: true })
      .first
    
    listing&.property
  end
  
  def handle_inactive_property(raw_email, property_code)
    error_message = "Email received for inactive property with code: #{property_code}"
    Rails.logger.warn error_message
    
    Leads::Creator.create_event_note(
      message: "CloudMailin email received for inactive property: #{property_code}\nEmail ID: #{raw_email.id}",
      error: true
    )
    
    raw_email.mark_failed!(error_message)
  end
  
  def handle_openai_failure(raw_email)
    # If OpenAI fails but we can retry, don't mark as failed yet
    if raw_email.can_retry?
      raw_email.update!(status: 'pending')
    else
      # After max retries, create a basic lead for manual review
      create_fallback_lead(raw_email)
    end
  end
  
  def create_lead_from_analysis(raw_email, analysis, property)
    lead_data = build_lead_data(analysis, raw_email, property)
    
    # Create lead directly since we've already processed the data
    source = determine_source(analysis, property) || LeadSource.find_by(slug: 'Cloudmailin')
    
    lead = Lead.new(lead_data)
    lead.lead_source_id = source&.id
    
    if lead.save
      raw_email.update!(
        status: 'completed',
        lead: lead,
        processed_at: Time.current,
        parser_used: 'OpenAI'
      )
      
      # Add note about AI classification
      if analysis['lead_type'] != 'rental_inquiry'
        Note.create!(
          notable: lead,
          classification: 'system',
          content: "AI Classification: #{analysis['lead_type'].humanize}\nReason: #{analysis['classification_reason']}\nConfidence: #{(analysis['confidence'] * 100).round}%"
        )
      end
    else
      error_message = "Lead creation failed: #{lead.errors.full_messages.join(', ')}"
      raw_email.mark_failed!(error_message)
    end
  end
  
  def build_lead_data(analysis, raw_email, property)
    lead_info = analysis['lead_data'] || {}
    
    # Handle uncertain/spam leads with descriptive names
    if analysis['is_lead'] == false || analysis['lead_type'] != 'rental_inquiry'
      first_name = lead_info['first_name'] || "Review Required"
      last_name = lead_info['last_name'] || analysis['lead_type'].humanize
    else
      first_name = lead_info['first_name']
      last_name = lead_info['last_name']
    end
    
    # Build clean lead data with only valid Lead model attributes
    clean_lead_data = {}
    
    # Lead model attributes
    clean_lead_data[:first_name] = first_name
    clean_lead_data[:last_name] = last_name
    clean_lead_data[:email] = lead_info['email'].presence || extract_email_from_header(raw_email.raw_data.dig('headers', 'From'))
    clean_lead_data[:phone1] = lead_info['phone1'] if lead_info['phone1'].present?
    clean_lead_data[:phone2] = lead_info['phone2'] if lead_info['phone2'].present?
    clean_lead_data[:company] = lead_info['company'] if lead_info['company'].present?
    clean_lead_data[:property_id] = property.id
    
    # Lead preference attributes
    preference_attrs = {}
    preference_attrs[:notes] = lead_info['notes'] if lead_info['notes'].present?
    preference_attrs[:move_in] = lead_info['preferred_move_in_date'] if lead_info['preferred_move_in_date'].present?
    preference_attrs[:unit_type] = lead_info['unit_type'] if lead_info['unit_type'].present?
    preference_attrs[:raw_data] = raw_email.raw_data.to_json
    
    clean_lead_data[:preference_attributes] = preference_attrs if preference_attrs.any?
    
    clean_lead_data
  end
  
  def determine_source(analysis, property)
    source_name = analysis['source_match']
    return nil unless source_name
    
    property.listings.active
      .joins(:source)
      .where(lead_sources: { name: source_name })
      .first&.source
  end
  
  def create_fallback_lead(raw_email)
    # Extract basic info from raw email
    headers = raw_email.raw_data['headers'] || {}
    from = headers['From'] || raw_email.raw_data.dig('envelope', 'from')
    subject = headers['Subject'] || 'No Subject'
    
    lead_data = {
      first_name: 'OpenAI Processing',
      last_name: 'Failed - Review',
      email: extract_email_from_header(from),
      preference_attributes: {
        notes: "Subject: #{subject}\n\nOpenAI processing failed. Please review raw email data."
      }
    }
    
    source = LeadSource.find_by(slug: 'Cloudmailin')
    lead = Lead.new(lead_data)
    lead.lead_source_id = source&.id
    
    if lead.save
      raw_email.update!(
        status: 'completed',
        lead: lead,
        processed_at: Time.current,
        parser_used: 'Fallback'
      )
      
      Note.create!(
        notable: lead,
        classification: 'error',
        content: "OpenAI processing failed after #{raw_email.retry_count} attempts. Manual review required."
      )
    end
  end
  
  def extract_email_from_header(from_header)
    return nil unless from_header
    
    # Extract email from headers like "John Doe <john@example.com>"
    match = from_header.match(/<(.+)>/)
    match ? match[1] : from_header.strip
  end
  
  def handle_error(raw_email, error)
    Rails.logger.error "ProcessCloudmailinEmailJob Error: #{error.message}\n#{error.backtrace.join("\n")}"
    
    if should_retry?(error)
      raw_email.update!(status: 'pending')
    else
      raw_email.mark_failed!(error.message)
    end
  end
  
  def should_retry?(error)
    error.is_a?(OpenaiClient::RateLimitError) || 
    error.is_a?(OpenaiClient::ServiceUnavailableError) ||
    error.is_a?(Net::ReadTimeout)
  end
end