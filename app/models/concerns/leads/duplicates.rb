module Leads
  module Duplicates
    extend ActiveSupport::Concern

    included do

      attr_accessor :skip_dedupe

      has_many :duplicate_records, class_name: 'DuplicateLead', foreign_key: 'reference_id', dependent: :destroy
      has_many :duplicate_records_by_lead_id, class_name: 'DuplicateLead', foreign_key: 'lead_id', dependent: :destroy
      has_many :duplicates, class_name: 'Lead', foreign_key: 'lead_id', through: :duplicate_records, source: :lead

      after_create :mark_duplicates
      after_save :duplicate_check_on_update

      HIGH_CONFIDENCE_DUPLICATE_MAX_AGE_DAYS = 60
      DUPLICATE_ATTRIBUTES = %w{phone1 phone2 email first_name last_name remoteid}
      DUPLICATE_IGNORED_VALUES = [
        '(None)',
        '(None)',
        '00000000',
        '000000000',
        '0000000000',
        '11111111 1111111111',
        '1111111111',
        '1234567890',
        '1234567891',
        '2222222222',
        '5',
        '5025555555',
        '5175551212',
        '5555555',
        '5555555555',
        '7777777777',
        '9999999999',
        'CALLER',
        'CELLULAR',
        'FREE',
        'Noemail@gmail.com',
        'None',
        'None@none.com',
        'None@none.zzz',
        'Null',
        'THE',
        'TOLL',
        'UNAVAILABLE',
        'UNKNOWN',
        'Unavailable',
        'Unknown',
        'WIRELESS',
        '[V]',
        'abc123@gmail.com',
        'didnothaveemail@gmail.com',
        'didnotwanttogive@gmail.com',
        'didntgive@nowhere.com',
        'n/a@gmail.com',
        'no.name@mane.com',
        'noemail@bluecrestresidential.com',
        'noemail@bluestone-prop.com',
        'noemail@bluestone-prop.zzz',
        'noemail@bluestone.com',
        'noemail@dont.com',
        'noemail@fake.com',
        'noemail@gmail.com',
        'noemail@gmail.zzz',
        'noemail@noemail.com',
        'noemail@noemail.zzz',
        'noemail@xyz.com',
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
        'none@none.com',
        'none@noreply.com',
        'noone@bluestone.zzz',
        'noreply@noreply.com',
        'unknown@noemail.com',
      ]

      RECENT=48.hours

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
        detected = possible_duplicates.order(created_at: :desc).limit(50)

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

        # TODO: MAYBE? for performance
        # self.skip_deupe = true

        after_mark_duplicates

        return detected
      end

      def after_mark_duplicates
        auto_invalidate
        unless invalidated?
          delay.broadcast_to_streams

          # Always attempt to send new lead messaging
          # Individual message types will check their own settings:
          # - SMS opt-in checks lead_auto_request_sms_opt_in
          # - Welcome email checks lead_auto_welcome
          send_new_lead_messaging
        end

        true
      end

      handle_asynchronously :after_mark_duplicates

      def duplicate_check_on_update
        mark_duplicates if duplicate_attribute_changed?
        return true
      end

      def duplicate_attribute_changed?
        changed_attributes = changes.merge(previous_changes).keys
        return DUPLICATE_ATTRIBUTES.any?{|a| changed_attributes.include?(a.to_s)}
      end

      handle_asynchronously :mark_duplicates, queue: :lead_dedupe

      def auto_invalidate
        invalidate_if_resident and return true
        #invalidate_if_duplicate_from_voyager and return true
        invalidate_if_high_confidence_duplicate and return true

        true
      end

      # Invalidate this lead if it is likely a resident
      # returns true only if invalidated
      def invalidate_if_resident
        return false unless property.present? && Lead.open_possible_residents(property).map{|opr| opr['id'] }.include?(id)

        self.classification = :resident
        self.transition_memo = 'Automatically invalidated as a Resident'
        trigger_event(event_name: 'invalidate')
        save
        reload
        true
      end

      # Invalidate this lead if it is likely a duplicate
      # returns true only if invalidated
      def invalidate_if_high_confidence_duplicate
        return false if invalidated?
        return false unless (message = auto_invalidate_lead?)

        self.classification = :duplicate
        self.transition_memo = "Automatically invalidated because #{message}"
        trigger_event(event_name: 'invalidate')
        save
        reload

        true
      end

      def auto_invalidate_lead?
        # Don't auto-invalidate leads assigned to system user (awaiting Lea AI handoff)
        # Check both the association and reload to ensure we have the current state
        return false if user_id.present? && User.find_by(id: user_id)&.system_user?

        # Don't auto-invalidate Lea handoff leads (they will match system user's lead as duplicate)
        return false if lea_conversation_url.present?

        # Phone number Matches invalidated leads classified as spam
        return 'this lead originated from a spam call' if spam_matches.any?

        # Check for feature flag
        return false unless Flipflop.enabled?(:lead_automatic_dedupe)

        # Abort if there are no matches
        dupes = high_confidence_duplicates.to_a
        return false unless dupes.any?

        # Don't auto-invalidate if any duplicates are system user leads or Lea handoff leads
        # This prevents regular leads from being invalidated when matched with Lea AI leads
        return false if dupes.any? { |lead| (lead.user_id.present? && User.find_by(id: lead.user_id)&.system_user?) || lead.lea_conversation_url.present? }

        # Abort if all of the duplicates belong to other properties
        return false if dupes.all?{|lead| lead.property_id != property_id }

        # Abort if all matches are already invalidated
        return false if dupes.all?{|lead| lead.classification == 'duplicate'}

        # At least one of the matches is in progress already
        in_progress_states = ['prospect', 'showing', 'application', 'approved']
        if ( matches = dupes.select{|lead| in_progress_states.include?(lead.state) } ).present?
          if open?
            # A match is currently being worked, so mark this new one as duplicate
            return 'a matching lead is already being worked'
          else
            # Mark as duplicate if any of the other currently worked matches were created first
            if matches.any?{|lead| lead.created_at < created_at }
              return 'a matching lead is already being worked'
            end
          end
        end

        # One of the matches is:
        #  1. from the same ILS
        #  2. submitted within 48h of each-other
        #  3. still open
        matches = dupes.select do |lead|
          create_delta = ( lead.created_at - created_at ).abs
          recent =  create_delta < RECENT
          same_referral = lead.referral == referral
          is_open = lead.open?
          same_referral && recent && is_open
        end
        if matches.any?
          return 'a matching lead was recently submitted by the same referrer'
        end

        non_worked_states = ['future', 'waitlist', 'resident', 'exresident']
        if (matches = dupes.select{|lead| non_worked_states.include?(lead.state)}).present?
          # Presence of resident matches implies a Resident contact, so this would be a duplicate
          # Otherwise this may be a valid contact
          if matches.any?{|lead| lead.resident?}
            return 'a matching lead is a resident'
          end
        end


        # Default to false (do not classify as duplicate)
        return false
      end


      def duplicates_with_matching_phone
        return Lead.where('1=0') unless phone1.present? || phone2.present?

        duplicates.where("phone1 = :phone OR phone2 = :phone OR phone1 = :phone2 OR phone2 = :phone2", {phone: phone1, phone2: phone2})
      end

      def high_confidence_duplicates
        return Lead.where('1=0') unless ( first_name.present? && last_name.present? ) && ( email.present? || phone1.present? )

        condition_hash = {start_date: HIGH_CONFIDENCE_DUPLICATE_MAX_AGE_DAYS.days.ago}
        conditions_str = '(created_at > :start_date)'
        conditions = []

        # Match same property
        if property_id.present?
          conditions << 'property_id = :property_id'
          condition_hash[:property_id] = property_id
          conditions_str += ' AND (' + conditions.join(' AND ') + ')'
          conditions = []
        end

        # Match first and last name
        conditions <<  'first_name = :first_name'
        condition_hash[:first_name] = first_name
        conditions <<  'last_name = :last_name'
        condition_hash[:last_name] = last_name
        conditions_str += ' AND (' + conditions.join(' AND ') + ')'
        conditions = []

        if email.present?
          conditions <<  'email = :email'
          condition_hash[:email] = email
        end
        if phone1.present?
          conditions <<  'phone1 = :phone1'
          condition_hash[:phone1] = phone1
        end
        conditions_str = conditions_str + ' AND (' + conditions.join(' OR ' ) + ')'

        duplicates.where(conditions_str, condition_hash)
      end
    end

    def spam_matches
      return Lead.where('1=0') unless phone1.present?

      conditions_hash = {}
      conditions_str = ''
      conditions = []

      # Match same property
      if property_id.present?
        conditions << 'property_id = :property_id'
        conditions_hash[:property_id] = property_id
        conditions_str += '(' + conditions.join(' AND ') + ') AND'
      end

      # Match leads marked as spam
      conditions = []
      conditions << 'state = :state'
      conditions << 'classification = :classification'
      conditions_hash[:state] = 'invalidated'
      conditions_hash[:classification] = Lead.classifications['spam']
      conditions_str += '(' + conditions.join(' AND ') + ')'

      # Match Phone
      conditions = []
      conditions << 'phone1 = :phone1'
      conditions_hash[:phone1] = phone1
      conditions_str += ' AND (' + conditions.join(' AND ' ) + ')'

      Lead.where(conditions_str, conditions_hash)
    end

    class_methods do

      def invalidate_open_resident_leads(property=nil)
        properties = property ? [property] : Property.active

        properties.each do |p|
          lead_ids = open_possible_residents(p).map{|r| r['id']}
          Lead.where(id: lead_ids).each do |lead|
            lead.classification = :resident
            lead.transition_memo = 'Automatically invalidated as a Resident'
            lead.trigger_event(event_name: 'invalidate')
            lead.save
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
