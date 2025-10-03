module Leads
  class ResidentProcessor

    def self.call
      self.new.call
    end

    def initialize(dry_run: false)
      @leads = []
      @seen_residents = {}
      @seen_leads = {}
      @dry_run = dry_run
    end

    def call
      puts "*** Correlating Residents with Active Leads."
      correlations.each {|c| transition_lead(c) }

      print_report
    end

    private

    # Find matching Leads and current Residents
    #
    def correlations
      ActiveRecord::Base.connection.execute(correlation_sql).to_a
    end

    def transition_lead(record)
      lead_id = record['id']
      resident_id = record['resident_id']

      lead = Lead.find(lead_id)
      if @seen_leads[lead_id]
        puts "! => Skipped duplicate Lead[#{lead_id}]"
        return lead
      end
      @seen_leads[lead_id] = true
      if lead.state == 'resident'
        puts "! => Skipped Lead already classified as a Resident"
        return lead
      end

      if lead.property_id.nil?
        puts "! => Skipped Lead without Property"
        return lead
      end

      resident = Resident.find(resident_id)
      if @seen_residents[resident_id]
        puts "! => Scanning for Lead[#{lead_id}] duplicates..."
        lead.mark_duplicates_without_delay
        if resident.lead_id.present?
          puts "! => Promoting Duplicate Lead[#{lead_id}] Match for Resident[#{resident_id}]"
          promote_lead(lead: lead, resident: resident)
        end
        return lead
      end
      @seen_residents[resident_id] = true
      if resident.status != 'current'
        puts "! => Skipped non-current Resident[#{resident_id}]"
      end

      old_state = lead.state

      ActiveRecord::Base.transaction do
        resident.lead_id = lead.id
        resident.save!
        promote_lead(lead: lead, resident: resident)
      end unless @dry_run

      @leads << lead

      msg = "=> Transitioned Lead[#{lead.id}](#{lead.name} #{lead.email}) from '#{old_state}' to 'resident' for Resident[#{resident.id}](#{resident.name} #{resident.detail.email})"
      puts msg
      Rails.logger.info msg

      lead
    end

    def promote_lead(lead:, new_state: 'resident', resident: nil)
      old_state = lead.state
      lead.state = new_state
      lead.set_priority_zero
      lead.set_conversion_date
      lead.save!
      lead.transition_memo = "Automatic transition due to matching Resident[#{resident&.id || '?'}]"
      lead.transition_user = User.system
      lead.create_lead_transition(last_state: old_state, current_state: new_state)
      lead.create_lead_transition_note(last_state: old_state, current_state: new_state)
      lead.clear_all_tasks
      lead.reload
      lead
    end

    def print_report
      puts "*** Updated #{@leads.count} Leads"
      #@leads.each do |lead|
        #puts "%{id},%{email},%{name},%{property},%{resident_id}" % {
          #id: lead.id,
          #email: lead.email,
          #name: lead.name,
          #property: lead.property&.name,
          #resident_id: lead&.resident&.id
        #}
      #end
      true
    end

    def correlation_sql
      last_updated = 7.days.ago

      sql = <<~SQL
        SELECT
        leads.id,
        leads.state,
        leads.first_name,
        leads.last_name,
        leads.phone1,
        leads.phone2,
        leads.email,
        leads.updated_at,
        resident_info.resident_id,
        resident_info.resident_status,
        resident_info.resident_first_name,
        resident_info.resident_last_name,
        resident_info.resident_phone1,
        resident_info.resident_phone2,
        resident_info.resident_email,
        resident_info.resident_created_at
      FROM
        leads
      INNER JOIN
        (
          SELECT
            residents.id AS resident_id,
            residents.property_id AS resident_property_id,
            residents.status AS resident_status,
            residents.first_name AS resident_first_name,
            residents.middle_name AS resident_middle_name,
            residents.last_name AS resident_last_name,
            resident_details.phone1 AS resident_phone1,
            resident_details.phone2 AS resident_phone2,
            resident_details.email AS resident_email,
            residents.created_at AS resident_created_at
          FROM
            residents
          INNER JOIN
            resident_details
            ON residents.id = resident_details.resident_id
          WHERE
            residents.status = 'current'
            AND residents.lead_id IS NULL
        ) resident_info
          ON ( leads.property_id = resident_info.resident_property_id
               AND LOWER(leads.last_name) = LOWER(resident_info.resident_last_name)
               AND ( leads.phone1 = resident_info.resident_phone1
                      OR leads.phone2 = resident_info.resident_phone2
                      OR leads.email = resident_info.resident_email) )
      WHERE
        leads.state NOT IN ('disqualified', 'abandoned', 'denied', 'resident')
      ORDER BY
        leads.created_at ASC
      ;
SQL
    end

  end
end
