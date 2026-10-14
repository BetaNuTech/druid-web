module Leads
  class ResidentValidator
    attr_reader :property, :lead_data, :matching_resident

    def initialize(property:, lead_data:)
      @property = property
      @lead_data = lead_data
      @matching_resident = nil
    end

    def resident_match?
      return false unless property.present?

      # Build conditions dynamically based on available data
      conditions = build_match_conditions
      return false if conditions.empty?

      # Check for matching residents
      result = find_matching_resident(conditions)

      if result.present?
        @matching_resident = result
        true
      else
        false
      end
    end

    private

    def build_match_conditions
      conditions = []
      invalid_values = Lead::DUPLICATE_IGNORED_VALUES

      # Phone matching conditions: either lead phone against either resident phone
      [lead_data[:phone1], lead_data[:phone2]].each do |phone|
        next unless phone.present? && !invalid_values.include?(phone)

        quoted = ActiveRecord::Base.connection.quote(phone)
        conditions << "(resident_details.phone1 = #{quoted} OR resident_details.phone2 = #{quoted})"
      end

      # Email matching condition (only if we have an email to check)
      if lead_data[:email].present? && !invalid_values.include?(lead_data[:email])
        conditions << "LOWER(resident_details.email) = #{ActiveRecord::Base.connection.quote(lead_data[:email].to_s.strip.downcase)}"
      end

      conditions
    end

    # Household members of some types (guarantors) share contact details with
    # a household while being legitimate prospects for a unit of their own:
    # they only count with a matching last name.
    def relationship_condition
      exempt = Resident::CONTACT_ONLY_EXEMPT_RELATIONSHIPS.map { |rel| ActiveRecord::Base.connection.quote(rel) }.join(', ')
      last_name = ActiveRecord::Base.connection.quote(lead_data[:last_name].to_s.strip.downcase)
      "(residents.relationship IS NULL OR residents.relationship NOT IN (#{exempt}) OR LOWER(residents.last_name) = #{last_name})"
    end

    def find_matching_resident(conditions)
      # Build the WHERE clause with OR conditions
      where_clause = conditions.join(' OR ')

      # Only select the fields we need for efficiency
      sql = <<~SQL
        SELECT#{' '}
          residents.id AS resident_id,
          residents.first_name,
          residents.last_name,
          resident_details.phone1,
          resident_details.phone2,
          resident_details.email
        FROM residents
        INNER JOIN resident_details ON resident_details.resident_id = residents.id
        WHERE residents.property_id = #{ActiveRecord::Base.connection.quote(property.id)}
          AND residents.status = 'current'
          AND (#{where_clause})
          AND #{relationship_condition}
        LIMIT 1
      SQL

      ActiveRecord::Base.connection.execute(sql).first
    end
  end
end
