require 'net/http'
require 'json'

class OpenaiClient
  class OpenaiError < StandardError; end
  class RateLimitError < OpenaiError; end
  class ServiceUnavailableError < OpenaiError; end
  
  OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions'
  MAX_RETRIES = 3
  RETRY_DELAY = 1 # seconds
  
  attr_reader :api_key, :organization, :model
  
  def initialize
    @api_key = ENV.fetch('OPENAI_API_TOKEN') { raise 'OPENAI_API_TOKEN not set' }
    @organization = ENV.fetch('OPENAI_ORG', nil)
    @model = ENV.fetch('OPENAI_MODEL', 'gpt-4o-mini')
    @circuit_open = false
    @last_failure_time = nil
  end
  
  def analyze_email(email_content, property, active_sources)
    return nil if circuit_open?
    
    # Get marketing sources for this property to help with matching
    marketing_sources = MarketingSource.where(property: property).active.pluck(:name)
    
    prompt = build_analysis_prompt(email_content, property, marketing_sources)
    
    request_body = {
      model: @model,
      response_format: { type: "json_object" },
      messages: [
        {
          role: "system",
          content: system_prompt(property)
        },
        {
          role: "user",
          content: prompt
        }
      ],
      temperature: 0.3,
      max_tokens: 1000
    }
    
    response = make_request_with_retries(request_body)
    parse_response(response)
  rescue => e
    Rails.logger.error "OpenAI Client Error: #{e.message}"
    handle_circuit_breaker(e)
    raise
  end
  
  private
  
  def circuit_open?
    return false unless @circuit_open
    
    # Check if circuit should be closed (5 minutes cooldown)
    if Time.current - @last_failure_time > 300
      @circuit_open = false
      Rails.logger.info "OpenAI circuit breaker closed"
    end
    
    @circuit_open
  end
  
  def handle_circuit_breaker(error)
    if error.is_a?(ServiceUnavailableError) || error.is_a?(RateLimitError)
      @circuit_open = true
      @last_failure_time = Time.current
      Rails.logger.error "OpenAI circuit breaker opened due to: #{error.class}"
    end
  end
  
  def make_request_with_retries(request_body)
    retries = 0
    
    begin
      uri = URI(OPENAI_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30
      http.open_timeout = 10
      
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{@api_key}"
      request['OpenAI-Organization'] = @organization if @organization
      request['Content-Type'] = 'application/json'
      request.body = request_body.to_json
      
      response = http.request(request)
      
      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 500, 502, 503, 504
        raise ServiceUnavailableError, "OpenAI service unavailable: #{response.code}"
      else
        raise OpenaiError, "OpenAI API error: #{response.code} - #{response.body}"
      end
      
    rescue Net::ReadTimeout, Net::OpenTimeout => e
      retries += 1
      if retries < MAX_RETRIES
        sleep(RETRY_DELAY * retries)
        retry
      else
        raise ServiceUnavailableError, "Timeout after #{MAX_RETRIES} retries: #{e.message}"
      end
    end
  end
  
  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return nil unless content
    
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse OpenAI response: #{e.message}"
    nil
  end
  
  def system_prompt(property)
    company_domain = ENV.fetch('COMPANY_EMAIL_DOMAIN', 'bluecrestresidential.com')
    invalid_prefixes = ENV.fetch('INVALID_EMAIL_PREFIXES', 'blueskyleads,leasing').split(',').map(&:strip)
    
    <<~PROMPT
      You are a lead classification system for #{property.name}. You are analyzing emails received by the leasing agents at #{property.name}. Anyone who has an email with domain #{company_domain} works for the property and is not a lead. Analyze incoming emails and:
      
      1. Determine if this is a legitimate rental inquiry (lead) vs resident communication, vendor email, spam, or other
      2. Extract contact information and inquiry details
      3. Match to the most appropriate marketing source if possible
      
      Return ONLY valid JSON with this exact structure:
      {
        "is_lead": true/false,
        "lead_type": "rental_inquiry|tour_booking|resident|vendor|spam|unknown|lea_handoff",
        "confidence": 0.0-1.0,
        "source_match": "source name or null",
        "has_sms_consent": true/false,
        "lea_conversation_url": "string or null",
        "lea_handoff_reason": "string or null",
        "lead_data": {
          "first_name": "string or null",
          "last_name": "string or null",
          "email": "string or null",
          "phone1": "string or null",
          "phone2": "string or null",
          "notes": "string or null",
          "preferred_move_in_date": "YYYY-MM-DD or null",
          "unit_type": "string or null",
          "company": "string or null"
        },
        "classification_reason": "brief explanation"
      }
      
      Important rules:
      - For uncertain/spam emails, still extract any available contact info
      - Phone numbers should be in format XXX-XXX-XXXX
      - If no clear first/last name, use descriptive placeholders like "Vendor" or "Unknown Sender"
      - Be conservative - only mark as spam if clearly spam
      - IMPORTANT: Do not select emails that start with any of these prefixes as the lead's email: #{invalid_prefixes.join(', ')}
      - If an email starts with any of these invalid prefixes (#{invalid_prefixes.join(', ')}), return null for the email field unless another valid email address is found in the email content
      - Only return null for email if no other valid email addresses are found

      GENERAL PROCESSING RULES:
      - For source_match: FIRST try to flexibly match against the Marketing Sources list provided for the property
      - Marketing Sources are the property's configured attribution sources (e.g., "Zillow", "Apartments.com", "Property Website")
      - Use flexible matching: "Zillow" matches "Zillow.com" or "Zillow Group", "Property Website" matches emails that appear to come from the property's website contact form, "Apartments.com" matches "Apartments.com" or "apartments.com", "Apartment List" matches "ApartmentList.com" or "apartmentlist.com"
      - If a Marketing Source can be reasonably matched based on email content, domain, or patterns, return that Marketing Source name exactly as configured
      - If no Marketing Source matches, return your best guess of the actual source based on email patterns, domains, from address, subject line, or content
      - Always return a source_match value - either a matched Marketing Source or your best guess of the source
      - Notes should add additional context from the lead data that would be helpful for the leasing agent to know
      - Check if the email indicates the lead has consented to be contacted at their phone number
      - Look for language patterns indicating consent to phone/SMS contact such as:
        * "consent to be contacted at the phone number"
        * "agree to receive text messages"
        * "opted in to SMS/text"
        * "consent to text"
        * References to agreeing to terms that include phone/text communication
      - This consent language typically appears in tour booking or registration confirmation emails
      - Set has_sms_consent: true if such consent language is detected

      TOUR BOOKING DETECTION:
      - lead_type: "tour_booking" if the email is a tour confirmation or booking
      - Detection criteria (ANY of these):
        1. Email confirms a scheduled tour with date/time
        2. Email contains "Tour" or "tour" with scheduled date/time information
        3. Email subject contains "Tour scheduled", "Tour confirmation", "Tour booking", "In-Person Tour", "Virtual Tour"
        4. Email body contains phrases like "tour is scheduled", "tour appointment", "showing scheduled", "property tour confirmed"
        5. Email appears to be from tour scheduling systems (e.g., Calendly, AppFolio, RentSpree, ShowMojo)
      - If detected as tour_booking:
        * Still extract all lead contact details
        * Set is_lead: true
        * Set confidence based on how clearly it's a tour booking
        * has_sms_consent may be true if consent language is present
        * Notes should include the tour date/time if available

      LEA AI HANDOFF DETECTION:
      - lead_type: "lea_handoff" if the email is a handoff from Lea AI assistant
      - Detection criteria (ALL must be present):
        1. Email body contains "Guest Card Details:" (case-insensitive)
        2. Email body contains the word "handoff" (case-insensitive)
        3. Email signature contains "Lea" or from address contains "lea@"
        4. Email contains a "View conversation" link or similar conversation URL
      - If detected as lea_handoff:
        * Extract the conversation URL from "View conversation" link → lea_conversation_url
        * Extract the handoff reason (e.g., "Tour request") → lea_handoff_reason
        * Still extract all lead contact details from "Guest Card Details" section
        * Set is_lead: true and confidence: 0.95+
    PROMPT
  end
  
  def build_analysis_prompt(email_content, property, marketing_sources = [])
    marketing_sources_list = marketing_sources.join(', ')
    
    # Handle both string and symbol keys
    content = email_content.with_indifferent_access
    
    <<~PROMPT
      Property: #{property.name}
      Property Address: #{property.address}
      Marketing Sources for this Property: #{marketing_sources_list.present? ? marketing_sources_list : 'None configured'}
      
      Email to analyze:
      
      From: #{content.dig('headers', 'From') || content.dig('envelope', 'from')}
      To: #{content.dig('headers', 'To') || content.dig('envelope', 'to')}
      Subject: #{content.dig('headers', 'Subject')}
      Date: #{content.dig('headers', 'Date')}
      
      Plain Text Content:
      #{content['plain'].presence || 'No plain text content'}
      
      HTML Content (if no plain text):
      #{content['plain'].blank? ? content['html'] : 'Omitted - plain text available'}
      
      Analyze this email and return the required JSON structure.
    PROMPT
  end
end