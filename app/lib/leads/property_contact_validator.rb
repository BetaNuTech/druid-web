module Leads
  class PropertyContactValidator
    attr_reader :property, :lead_data, :result, :modifications, :rejection_reason

    def initialize(property:, lead_data:)
      @property = property
      @lead_data = lead_data
      @result = :ok
      @modifications = {}
      @rejection_reason = nil
    end

    def validate
      return :ok unless property.present?

      email_matches = email_domain_matches_property?
      phone_matches = phone_matches_property?
      lead_has_email = lead_data[:email].present?
      lead_has_phone = (lead_data[:phone1] || lead_data[:phone2]).present?

      if email_matches && phone_matches
        @result = :reject
        @rejection_reason = "Lead email domain and phone match property contact info"
      elsif email_matches && !lead_has_phone
        @result = :reject
        @rejection_reason = "Lead email domain matches property (no alternative contact)"
      elsif phone_matches && !lead_has_email
        @result = :reject
        @rejection_reason = "Lead phone matches property (no alternative contact)"
      elsif email_matches && lead_has_phone
        @result = :modify
        @modifications = { email: nil, reason: "Email domain matched property" }
      elsif phone_matches && lead_has_email
        @result = :modify
        @modifications = { phone1: nil, phone2: nil, reason: "Phone matched property" }
      end

      @result
    end

    def should_reject?
      @result == :reject
    end

    def should_modify?
      @result == :modify
    end

    private

    def email_domain_matches_property?
      return false unless lead_data[:email].present?
      lead_domain = extract_email_domain(lead_data[:email])
      return false unless lead_domain.present?

      property_domains.any? { |d| d == lead_domain }
    end

    def phone_matches_property?
      lead_phones = [lead_data[:phone1], lead_data[:phone2]]
        .compact.reject(&:blank?)
        .map { |p| PhoneNumber.format_phone(p) }
      return false if lead_phones.empty?

      (lead_phones & all_property_phones).any?
    end

    def extract_email_domain(email)
      return nil unless email&.include?('@')
      email.split('@').last&.downcase&.strip
    end

    def extract_website_domain(url)
      return nil unless url.present?
      url_with_protocol = url.start_with?('http') ? url : "https://#{url}"
      URI.parse(url_with_protocol).host&.downcase&.sub(/^www\./, '')
    rescue URI::InvalidURIError
      nil
    end

    def property_domains
      domains = []
      domains << extract_email_domain(property.email) if property.email.present?
      domains << extract_website_domain(property.website) if property.website.present?
      domains.compact.uniq
    end

    def all_property_phones
      phones = [property.phone, property.leasing_phone, property.maintenance_phone]
      phones += property.phone_numbers.map(&:number) if property.respond_to?(:phone_numbers)
      phones.compact.reject(&:blank?).map { |p| PhoneNumber.format_phone(p) }.uniq
    end
  end
end
