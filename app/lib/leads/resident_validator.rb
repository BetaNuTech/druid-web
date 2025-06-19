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

      # Phone matching conditions
      if lead_data[:phone1].present? && !invalid_values.include?(lead_data[:phone1])
        conditions << "resident_details.phone1 = #{ActiveRecord::Base.connection.quote(lead_data[:phone1])}"
      end

      if lead_data[:phone2].present? && !invalid_values.include?(lead_data[:phone2])
        conditions << "resident_details.phone2 = #{ActiveRecord::Base.connection.quote(lead_data[:phone2])}"
      end

      # Email matching condition (only if we have an email to check)
      if lead_data[:email].present? && !invalid_values.include?(lead_data[:email])
        conditions << "resident_details.email = #{ActiveRecord::Base.connection.quote(lead_data[:email])}"
      end

      conditions
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
        LIMIT 1
      SQL

      ActiveRecord::Base.connection.execute(sql).first
    end
  end
end
