module Leads
  module Duplicates
    extend ActiveSupport::Concern

    included do

      attr_accessor :skip_dedupe

      has_many :duplicate_records, class_name: 'DuplicateLead', foreign_key: 'reference_id', dependent: :destroy
      has_many :duplicates, class_name: 'Lead', foreign_key: 'lead_id', through: :duplicate_records, source: :lead

      after_create :mark_duplicates
      after_save :duplicate_check_on_update

      DUPLICATE_ATTRIBUTES = %w{phone1 phone2 email first_name last_name}
      DUPLICATE_IGNORED_VALUES = %w{ none@gmail.com Null 00000000 0000000000 (None) None non@aol.zzz non@aol.com none@aol.zzz none@aol.com noemail@bluestone.com noemail@xyz.zzz noemail@noemail.zzz }

      def possible_duplicates
        invalid_values_sql = DUPLICATE_IGNORED_VALUES.map{|v| "'#{v}'"}.join(', ')

        sql_template =<<~SQL

          SELECT leads.id
          FROM leads
          WHERE
            ( id != :id )
            AND (
              ( phone1 IS NOT NULL
                AND phone1 != ''
                AND phone1 = :phone1
                AND phone1 NOT IN (#{invalid_values_sql})
              )
              OR ( phone2 IS NOT NULL
                   AND phone2 != ''
                   AND phone2 = :phone2
                   AND phone2 NOT IN (#{invalid_values_sql})
                 )
              OR ( first_name IS NOT NULL
                   AND first_name != ''
                   AND first_name = :first_name
                   AND last_name = :last_name
                   AND first_name NOT IN (#{invalid_values_sql})
                 )
              OR ( email IS NOT NULL
                   AND email != ''
                   AND email = :email
                   AND email NOT IN (#{invalid_values_sql})
                 )
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

        lead_ids = result.to_a.map{|r| r['id']}
        return Lead.where(id: lead_ids)
      end

      # Find and mark duplicates if self.skip_dedupe is not TRUE
      def mark_duplicates(recurse=true)
        self.skip_dedupe ||= false
        if self.skip_dedupe == true
          return true
        end

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

          if recurse
            # Update XOR'ed list of old and newly detected duplicates
            refresh_leads = ( (old_duplicates + detected) - ( old_duplicates & detected) ).uniq
            refresh_leads.each{|od| od.mark_duplicates(false)}
          end
        end

        return detected
      end

      def duplicate_check_on_update
        mark_duplicates if duplicate_attribute_changed?
        return true
      end

      def duplicate_attribute_changed?
        changed_attributes = changes.merge(previous_changes).keys
        return DUPLICATE_ATTRIBUTES.any?{|a| changed_attributes.include?(a.to_s)}
      end

      handle_asynchronously :mark_duplicates, queue: :lead_dedupe
    end
  end
end
