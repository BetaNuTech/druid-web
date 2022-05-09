module Residents
  class LeadMatcher

    def call
      collection = matching_active_leads
      collection.each do |match|
        lead = match[:lead]
        resident = match[:resident]
        ActiveRecord::Base.transaction do
          lead.force_lodge(memo: "detected match with Resident[#{resident.id}]")
          resident.lead = lead
          resident.save!
        end
      end

      collection
    end

    def matching_active_leads
      join_sql = <<~SQL
        INNER JOIN properties ON
          leads.property_id = properties.id AND properties.active = true
        INNER JOIN resident_details ON
        ((leads.phone1 IS NOT NULL AND leads.phone1 = resident_details.phone1) OR
         (leads.phone2 IS NOT NULL AND leads.phone2 = resident_details.phone2) OR
         (leads.email IS NOT NULL AND leads.email = resident_details.email))
         JOIN residents ON residents.id = resident_details.resident_id
       SQL

       collection = Lead.
         select("leads.*, residents.id AS resident_id").
         joins(join_sql).
         where(state: Leads::StateMachine::IN_PROGRESS_STATES).
         where("leads.last_name = residents.last_name")
       residents = Resident.current.where(id: collection.pluck(:resident_id), lead_id: nil).inject({}){|memo, obj| memo[obj.id] = obj; memo}

       collection.map do |lead|
         next if (resident = residents.fetch(lead.resident_id, nil)).nil?
         { lead: lead, resident: resident }
       end.compact
    end

  end
end
