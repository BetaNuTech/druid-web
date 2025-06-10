class CloudmailinRawEmail < ApplicationRecord
  belongs_to :property, optional: true
  belongs_to :lead, optional: true

  validates :raw_data, presence: true
  
  scope :pending, -> { where(status: 'pending') }
  scope :failed, -> { where(status: 'failed') }
  scope :retryable, -> { where(status: 'failed').where('retry_count < ?', 3) }
  
  def self.create_from_params(params, property_code)
    # Convert params to hash, handling both ActionController::Parameters and Hash
    raw_data = if params.respond_to?(:to_unsafe_h)
                 params.to_unsafe_h
               else
                 params.is_a?(Hash) ? params : params.to_h
               end
               
    create!(
      raw_data: raw_data,
      property_code: property_code,
      status: 'pending'
    )
  end
  
  def process!
    update!(status: 'processing')
    ProcessCloudmailinEmailJob.perform_later(self)
  end
  
  def mark_completed!(lead)
    update!(
      status: 'completed',
      lead: lead,
      processed_at: Time.current
    )
  end
  
  def mark_failed!(error_message)
    update!(
      status: 'failed',
      error_message: error_message,
      retry_count: retry_count + 1
    )
  end
  
  def can_retry?
    retry_count < 3
  end
end