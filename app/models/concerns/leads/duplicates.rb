module Leads
  module Duplicates
    extend ActiveSupport::Concern

    included do
      has_many :duplicate_records, class_name: 'DuplicateLead', foreign_key: 'reference_id', dependent: :destroy
      has_many :duplicates, class_name: 'Lead', foreign_key: 'lead_id', through: :duplicate_records, source: :lead

      after_save :mark_duplicates

      DUPLICATE_ATTRIBUTES = %w{phone1 phone2 email first_name last_name}

      def possible_duplicates
        sql_template =<<~SQL

          SELECT leads.id
          FROM leads
          WHERE
          ( id != :id )
          AND
          (
            ( phone1 = :phone1 AND phone1 != 'Null' AND phone1 != '00000000' AND phone1 != '0000000000' AND phone1 != '' AND phone1 IS NOT NULL ) OR
            ( phone2 = :phone2 AND phone2 != 'Null' AND phone2 != '00000000' AND phone2 != '0000000000' AND phone2 != '' AND phone2 IS NOT NULL) OR
            ( first_name = :first_name AND last_name = :last_name AND first_name != 'Null' AND first_name IS NOT NULL) OR
            ( email = :email AND email != 'Null' AND email IS NOT NULL )
          )
          SQL

        query_array = [
          sql_template,
          id: id,
          first_name: first_name, last_name: last_name,
          phone1: phone1, phone2: phone2, email: email
        ]

        sql = Lead.sanitize_sql_array(query_array)
        result = ActiveRecord::Base.connection.execute(sql)

        lead_ids = result.to_a.map{|r| r["id"]}
        return Lead.where(id: lead_ids)
      end

      def mark_duplicates
        detected = possible_duplicates
        transaction do
          old_duplicates = duplicates.to_a

          # Create New DuplicateLead records
          detected_ids = detected.select(:id).map(&:id)
          detected_ids.each do |candidate_id|
            DuplicateLead.create(reference_id: id, lead_id: candidate_id)
          end

          # Delete stale DuplicateLead records
          duplicate_records.where("lead_id NOT IN (?)", detected_ids).destroy_all

          # Update XOR'ed list of old and newly detected duplicates
          refresh_leads = ( (old_duplicates + detected) - ( old_duplicates & detected) ).uniq
          refresh_leads.each{|od| od.mark_duplicates}
        end

        return detected
      end

      def duplicate_check_on_update
        mark_duplicates if duplicate_attribute_changed?
        return true
      end

      def duplicate_attribute_changed?
        return false unless ( new_record? || changed? )
        changed_attributes = changes.keys
        return DUPLICATE_ATTRIBUTES.any?{|a| changed_attributes.include?(a.to_s)}
      end

      handle_asynchronously :mark_duplicates
    end
  end
end
