# == Schema Information
#
# Table name: properties
#
#  id                   :uuid             not null, primary key
#  name                 :string
#  address1             :string
#  address2             :string
#  address3             :string
#  city                 :string
#  state                :string
#  zip                  :string
#  country              :string
#  organization         :string
#  contact_name         :string
#  phone                :string
#  fax                  :string
#  email                :string
#  units                :integer
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  active               :boolean          default(TRUE)
#  website              :string
#  school_district      :string
#  amenities            :text
#  application_url      :string
#  team_id              :uuid
#  call_lead_generation :boolean          default(TRUE)
#  maintenance_phone    :string
#  working_hours        :jsonb
#  timezone             :string           default("UTC"), not null
#  leasing_phone        :string
#  voice_menu_enabled   :boolean          default(FALSE)
#  appsettings          :jsonb
#  tour_booking_url     :string

class Property < ApplicationRecord
  ### Class Concerns/Extensions
  include Properties::Appsettings
  include Properties::Team
  include Properties::Users
  include Properties::PhoneNumbers
  include Properties::MarketingSources
  include Properties::Logo
  include Properties::WorkingHours
  include Properties::Scheduling
  include Properties::YardiVoyager
  audited

  ### Constants

  ALLOWED_PARAMS = [ :name, :address1, :address2, :address3, :city, :state, :zip, :country,
                    :organization, :contact_name, :phone, :maintenance_phone, :leasing_phone,
                    :fax, :email, :website, :units, :notes, :school_district,
                    :amenities, :active, :application_url, :tour_booking_url, :team_id, :timezone,
                    :logo, :remove_logo,
                    :email_header_image,
                    :email_footer_logo,
                    :call_lead_generation, :voice_menu_enabled,
                    { working_hours: {} } ]

  ## Associations
  has_many :leads
  has_many :listings, class_name: 'PropertyListing', dependent: :destroy
  accepts_nested_attributes_for :listings, reject_if: proc{|attributes| attributes['code'].blank? && attributes['description'].blank? }
  has_many :unit_types, dependent: :destroy
  has_many :housing_units, class_name: 'Unit', dependent: :destroy
  has_many :residents, dependent: :destroy
  has_many :engagement_policies, dependent: :destroy
  has_many :comments, class_name: "Note", as: :notable, dependent: :destroy
  has_many :contact_events, through: :leads
  has_many :referral_bounces, dependent: :destroy

  ### Validations
  validates :name, presence: true, uniqueness: true
  validates :timezone, presence: true

  ### Scopes
  scope :active, -> { where(active: true) }
  scope :supporting_call_lead_generation, -> { where(call_lead_generation: true)}

  ### Callbacks
  before_validation :format_phones
  before_create :set_default_messages

  ### Class Methods

  # Lookup by ID or PropertyListing code
  def self.find_by_code_and_source(code:, source_id: nil)
    if source_id.nil?
      return Property.active.where(id: code).first
    else
      return PropertyListing.includes(:source).
        where( lead_sources: {id: source_id, active: true},
               property_listings: {code: code, active: true}).
        first.try(:property)
    end
  end

  def self.names_and_ids
    self.order(:name).pluck(:name, :id)
  end

  ## Instance Methods

  # Return array of all possible PropertyListings for this property.
  def present_and_possible_listings
    return ( listings + missing_listings ).sort_by{|l| l.source.try(:name) || ''}
  end

  # Return an array of PropertyListings which are not present for
  # this property
  def missing_listings
    LeadSource.where.not(id: [listings.map(&:source_id)]).map do |source|
      PropertyListing.new(property_id: self.id, source_id: source.id, active: false)
    end
  end

  def listing_code(source)
    return nil unless source.present?
    self.listings.where(source_id: source.id).first.try(:code)
  end

  def occupancy_rate
    (housing_units.occupied.count.to_f / [ housing_units.count || 1].min.to_f).round(1) * 100.0
  end

  def address(line_break="\n")
    [address1, address2, address3, "#{city} #{state} #{zip}"].
      compact.
      select{|c| (c || '').length > 0}.
      join(line_break)
  end

  def address_html
    address("<BR/>")
  end

  def duplicate_groups
    DuplicateLead.includes("lead").where(leads: {property_id: self.id}).groups
  end

  # Default SMS message templates (kept under 160 chars for single segment)
  DEFAULT_SMS_OPT_IN_REQUEST = "Thanks for your interest in {{property_name}}! Reply YES to receive text updates about availability and tours. Reply STOP to opt out."
  DEFAULT_SMS_OPT_IN_CONFIRMATION = "You're in! Your dedicated {{property_name}} leasing team is ready to help. Schedule your tour today: {{property_tour_booking_url}}"
  DEFAULT_SMS_OPT_OUT_CONFIRMATION = "You've been unsubscribed from {{property_name}} texts. Reply YES anytime to resubscribe."
  DEFAULT_WELCOME_EMAIL_SUBJECT = "Welcome to {{property_name}}!"
  DEFAULT_WELCOME_EMAIL_BODY = "<p>Dear {{lead_first_name}},</p><p>Thank you for your interest in {{property_name}}! We're thrilled that you're considering our community as your next home.</p><p>Our team is committed to making your apartment search as smooth and enjoyable as possible. One of our experienced leasing professionals will be reaching out to you shortly to:</p><ul><li>Discuss your specific housing needs and preferences</li><li>Answer any questions about our community and amenities</li><li>Schedule a personalized tour at your convenience</li></ul><p><strong>Ready to see your future home?</strong></p><center style=\"margin: 20px 0;\"><a href=\"{{property_tour_booking_url}}\" style=\"display: inline-block; padding: 12px 30px; background-color: #007bff; color: #ffffff; text-decoration: none; border-radius: 5px; font-weight: bold; font-size: 16px;\">Book a Tour Now</a></center><p><strong>Explore Our Community Online</strong><br>While you wait to hear from us, we invite you to visit <a href=\"{{property_website}}\">{{property_website}}</a> to:</p><ul><li>Browse our available floor plans and pricing</li><li>View our extensive amenities and community features</li><li>Take a virtual tour of our property</li><li>Learn about our neighborhood and local attractions</li></ul><p>If you have any immediate questions, please don't hesitate to call us at {{property_phone}} or reply to this email.</p><p>We look forward to welcoming you to {{property_name}} and helping you find the perfect place to call home!</p><p>Warm regards,<br>The {{property_name}} Team</p>"

  # Methods to get messages with defaults
  def sms_opt_in_request_message_with_default
    sms_opt_in_request_message.presence || DEFAULT_SMS_OPT_IN_REQUEST
  end

  def sms_opt_in_confirmation_message_with_default
    sms_opt_in_confirmation_message.presence || DEFAULT_SMS_OPT_IN_CONFIRMATION
  end

  def sms_opt_out_confirmation_message_with_default
    sms_opt_out_confirmation_message.presence || DEFAULT_SMS_OPT_OUT_CONFIRMATION
  end

  def lead_auto_welcome_email_subject_with_default
    lead_auto_welcome_email_subject.presence || DEFAULT_WELCOME_EMAIL_SUBJECT
  end

  def lead_auto_welcome_email_body_with_default
    lead_auto_welcome_email_body.presence || DEFAULT_WELCOME_EMAIL_BODY
  end

  # Validation for required keywords in opt-in request
  validate :sms_opt_in_includes_required_keywords, if: -> {
    has_attribute?(:sms_opt_in_request_message) && sms_opt_in_request_message.present?
  }

  def sms_opt_in_includes_required_keywords
    message_text = sms_opt_in_request_message.downcase

    # Check for opt-in keywords (YES or similar)
    opt_in_keywords = ['yes', 'si', 'ok', 'okay', 'sure', 'start']
    has_opt_in = opt_in_keywords.any? { |keyword| message_text.include?(keyword) }

    unless has_opt_in
      errors.add(:sms_opt_in_request_message, "must include instructions to reply 'YES' or similar keyword (#{opt_in_keywords.join(', ').upcase}) to opt-in")
    end

    # Check for opt-out keywords (STOP or similar)
    opt_out_keywords = ['stop', 'detener', 'cancel', 'unsubscribe', 'opt out', 'opt-out']
    has_opt_out = opt_out_keywords.any? { |keyword| message_text.include?(keyword) }

    unless has_opt_out
      errors.add(:sms_opt_in_request_message, "must include the word 'STOP' or similar keyword for opt-out option (TCPA compliance)")
    end
  end

  private

  def format_phones
    self.phone = PhoneNumber.format_phone(self.phone) if self.phone.present?
    self.maintenance_phone = PhoneNumber.format_phone(self.maintenance_phone) if self.maintenance_phone.present?
    self.leasing_phone = PhoneNumber.format_phone(self.leasing_phone) if self.leasing_phone.present?
    self.fax = PhoneNumber.format_phone(self.fax) if self.fax.present?
  end

  def set_default_messages
    # Only set defaults if the columns exist (protects during migrations)
    if has_attribute?(:sms_opt_in_request_message)
      # Set default SMS messages if not provided
      self.sms_opt_in_request_message ||= DEFAULT_SMS_OPT_IN_REQUEST
      self.sms_opt_in_confirmation_message ||= DEFAULT_SMS_OPT_IN_CONFIRMATION
      self.sms_opt_out_confirmation_message ||= DEFAULT_SMS_OPT_OUT_CONFIRMATION

      # Set default email messages if not provided
      self.lead_auto_welcome_email_subject ||= DEFAULT_WELCOME_EMAIL_SUBJECT
      self.lead_auto_welcome_email_body ||= DEFAULT_WELCOME_EMAIL_BODY
    end

    # Set default appsettings for SMS opt-in
    self.appsettings ||= {}
    self.appsettings['lead_auto_request_sms_opt_in'] ||= '1'
  end

end
