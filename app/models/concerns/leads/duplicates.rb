module Leads
  module Duplicates
    extend ActiveSupport::Concern

    included do

      attr_accessor :skip_dedupe

      has_many :duplicate_records, class_name: 'DuplicateLead', foreign_key: 'reference_id', dependent: :destroy
      has_many :duplicates, class_name: 'Lead', foreign_key: 'lead_id', through: :duplicate_records, source: :lead

      after_create :mark_duplicates, :disqualify_if_resident
      after_save :duplicate_check_on_update

      DUPLICATE_ATTRIBUTES = %w{phone1 phone2 email first_name last_name remoteid}
      DUPLICATE_IGNORED_VALUES = [
        '(None)',
        '00000000',
        '000000000',
        '0000000000',
        '11111111 1111111111',
        '1111111111',
        '1234567890',
        '1234567891',
        '2222222222',
        '5025555555',
        '5555555',
        '5555555555',
        '7777777777',
        '9999999999',
        '5175551212',
        'CALLER',
        'CELLULAR',
        'FREE',
        'abc123@gmail.com',
        'noemail@xyz.com',
        '5',
        'Noemail@gmail.com',
        'None',
        'None@none.com',
        'None@none.zzz',
        'Null',
        'TOLL',
        'Unavailable',
        'WIRELESS',
        'didnothaveemail@gmail.com',
        'didnotwanttogive@gmail.com',
        'didntgive@nowhere.com',
        'n/a@gmail.com',
        'no.name@mane.com',
        'noemail@bluestone-prop.com',
        'noemail@bluestone-prop.zzz',
        'noemail@bluestone.com',
        'noemail@dont.com',
        'noemail@gmail.com',
        'noemail@gmail.zzz',
        'noemail@fake.com',
        'noemail@noemail.com',
        'noemail@noemail.zzz',
        'noemail@xyz.zzz',
        'noemail@yahoo.com',
        'noemail@yahoo.zzz',
        'non@aol.com',
        'non@aol.zzz',
        'noname@gmail.zzz',
        'none@aol.com',
        'none@aol.zzz',
        'none@bluestone-prop.zzz',
        'none@bluestone.com',
        'none@bluestone.zzz',
        'none@gmail.com',
        'none@gmail.com',
        'none@gmail.zzz',
        'none@none.com',
        'none@noreply.com',
        'noone@bluestone.zzz',
        'noreply@noreply.com',
        'unknown@noemail.com'
      ]

      def has_duplicates?
        duplicate_records.any?
      end

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
              OR ( remoteid IS NOT NULL
                   AND remoteid != ''
                   AND remoteid = :remoteid
                   AND remoteid NOT IN (#{invalid_values_sql})
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

          ORDER BY created_at DESC

        SQL

        query_array = [
          sql_template,
          id: id,
          first_name: first_name, last_name: last_name,
          phone1: phone1, phone2: phone2, email: email,
          remoteid: remoteid
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

        # Processing more than 10 duplicate candidates is a waste of resources
        # and consistently causes backlogs in the queue
        detected = possible_duplicates.limit(10)

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

      def disqualify_if_resident
        if Lead.open_possible_residents(property).map{|opr| opr['id'] }.include?(id)
          self.classification = :resident
          self.transition_memo = 'Automatically disqualified as a Resident'
          trigger_event(event_name: 'disqualify')
          reload
        end
      end

      handle_asynchronously :disqualify_if_resident, queue: :lead_dedupe
    end

    class_methods do

      def disqualify_open_resident_leads(property=nil)
        properties = property ? [property] : Property.active

        properties.each do |p|
          lead_ids = open_possible_residents(p).map{|r| r['id']}
          Lead.where(id: lead_ids).each do |lead|
            lead.classification = :resident
            lead.transition_memo = 'Automatically disqualified as a Resident'
            lead.trigger_event(event_name: 'disqualify')
          end
        end
      end

      def open_possible_residents_csv
        data = []
        Property.active.each do |property|
          data += open_possible_residents(property)
        end
        CSV.generate do |csv|
          csv << ['Property', 'Lead First Name', 'Lead Last Name', 'Lead Phone 1', 'Lead Phone 2', 'Lead Email', 'Resident First Name', 'Resident Last Name', 'Resident Phone 1', 'Resident Phone 2', 'Resident Email', 'Resident ID', 'Lead ID', 'Lead URL', 'Resident URL']
          data.each do |row|
            lead_base = 'https://www.blue-sky.app/leads/%s'
            resident_base = 'https://www.blue-sky.app/residents/%s'
            csv << row.to_a.map{|c| c.last} + [
              lead_base % [row['id']],
              resident_base % [row['resident_id']],
            ]
          end
        end
      end

      def open_possible_residents(property)
        invalid_values_sql = DUPLICATE_IGNORED_VALUES.map{|v| "'#{v}'"}.join(', ')

        sql = <<~SQL
          SELECT
            properties.name AS property_name,
            leads.first_name AS lead_first_name,
            leads.last_name AS lead_last_name,
            leads.phone1 AS lead_phone1,
            leads.phone2 AS lead_phone2,
            leads.email AS lead_email,
            resident_info.resident_first_name AS resident_first_name,
            resident_info.resident_last_name AS resident_last_name,
            resident_info.resident_phone1 AS resident_phone1,
            resident_info.resident_phone2 AS resident_phone2,
            resident_info.resident_email AS resident_email,
            resident_info.resident_id AS resident_id,
            leads.id AS id
          FROM
            leads
          INNER JOIN properties
            ON leads.property_id = properties.id
          INNER JOIN (
            SELECT
              residents.id AS resident_id,
              residents.first_name as resident_first_name,
              residents.last_name as resident_last_name,
              resident_details.phone1 AS resident_phone1,
              resident_details.phone2 AS resident_phone2,
              resident_details.email AS resident_email
            FROM residents
            INNER JOIN resident_details
              ON resident_details.resident_id = residents.id
            WHERE
              residents.property_id = '#{property.id}' AND
              residents.status = 'current'
          ) resident_info
            ON (
              (
                leads.phone1 != '' AND
                leads.phone1 = resident_info.resident_phone1 AND
                leads.phone1 NOT IN (#{invalid_values_sql})
              ) OR
              (
                leads.phone2 != '' AND
                leads.phone2 = resident_info.resident_phone2 AND
                leads.phone2 NOT IN (#{invalid_values_sql})
              ) OR
              (
                leads.email != '' AND
                leads.email = resident_info.resident_email AND
                leads.email NOT IN (#{invalid_values_sql})
              ) OR
              (
                leads.first_name = resident_info.resident_first_name AND
                leads.last_name = resident_info.resident_last_name AND
                leads.first_name NOT IN (#{invalid_values_sql}) AND
                leads.last_name NOT IN (#{invalid_values_sql})
              )
            )
          WHERE
            leads.state = 'open' AND
            leads.property_id = '#{property.id}';
        SQL

        ActiveRecord::Base.connection.execute(sql).to_a
      end
    end
  end
end
