FactoryBot.define do
  factory :cloudmailin_raw_email do
    raw_data {
      {
        headers: {
          'From' => 'test@example.com',
          'To' => 'property+123@cloudmailin.net',
          'Subject' => 'Test Email',
          'Date' => Time.current.to_s
        },
        envelope: {
          from: 'test@example.com',
          to: 'property+123@cloudmailin.net'
        },
        plain: 'This is a test email message.',
        html: '<p>This is a test email message.</p>'
      }
    }
    property_code { '123' }
    status { 'pending' }
    retry_count { 0 }
    
    trait :processing do
      status { 'processing' }
    end
    
    trait :completed do
      status { 'completed' }
      processed_at { Time.current }
      association :lead
    end
    
    trait :failed do
      status { 'failed' }
      error_message { 'Processing failed' }
      retry_count { 1 }
    end
    
    trait :with_property do
      association :property
      property_code { property.id.to_s }
    end
    
    trait :with_openai_response do
      openai_response {
        {
          'is_lead' => true,
          'lead_type' => 'rental_inquiry',
          'confidence' => 0.95,
          'source_match' => 'Zillow',
          'lead_data' => {
            'first_name' => 'John',
            'last_name' => 'Doe',
            'email' => 'john@example.com',
            'phone1' => '555-123-4567'
          },
          'classification_reason' => 'Email contains rental inquiry'
        }
      }
      openai_confidence_score { 0.95 }
    end
  end
end