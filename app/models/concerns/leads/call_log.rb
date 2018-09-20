module Leads
  module CallLog
    extend ActiveSupport::Concern

    included do

      CALL_LOG_FREQUENCY = 10 # minutes

      scope :recent_recordings, -> (start_time=1.week.ago) {
        leads = {}
        lead_phone_numbers = self.all.inject({}) do |memo, lead|
          phones = [lead.phone1, lead.phone2].compact
          if phones.size > 0
            memo[lead.id] = Cdr.number_variants(phones)
          end
          memo
        end
        phone_numbers = lead_phone_numbers.to_a.map{|l| l[1]}.flatten.compact.uniq
        call_records = Cdr.where('( recordingfile IS NOT NULL AND recordingfile != "" ) AND calldate >= ?', start_time).
          calls_for(phone_numbers).
          to_a
        lead_phone_numbers.each_pair do |leadid, phones|
          cdr_matches = call_records.select{|cdr| phones.include?(cdr.src) || phones.include?(cdr.dst)}
          if cdr_matches.present?
            leads[leadid] = { lead: Lead.find(leadid), calls: cdr_matches }
          end
        end
        leads
      }

      # Return Hash of cached call information
      def calls
        #if should_update_call_log?
          #delay.update_call_log
        #end
        return JSON.parse(call_log || '[]')
      end

      def update_call_log
        if should_update_call_log?
          transaction do
            self.call_log = Cdr.calls_for([phone1, phone2]).
              map{|cdr|
              { id: cdr.id,
                date: cdr.calldate,
                src: cdr.src,
                dst: cdr.dst,
                disposition: cdr.disposition,
                recordingfile: cdr.recordingfile,
                recording_path: cdr.recording_path,
                recording_type: cdr.recording_media_type }
            }.to_json
            self.call_log_updated_at = DateTime.now
            save
          end
        end
        return JSON.parse(self.call_log)
      end

      def should_update_call_log?
        return (call_log.nil? || call_log.empty? || call_log_updated_at.nil? || call_log_updated_at < (DateTime.now - CALL_LOG_FREQUENCY.minutes))
      end
    end

    class_methods do

      def from_recent_calls(start_date:, end_date:)
        default_source = LeadSource.default

        call_leads = Cdr.possible_leads(start_date: start_date, end_date: end_date)

        incoming_dids = call_leads.map{|l| l.did}
        incoming_sources = call_leads.map{|l| l.src}
        incoming_properties = Property.find_all_by_phone_numbers(incoming_dids)
        incoming_properties_numbers = incoming_properties.map{|ip| [ip, ip.all_numbers]}
        incoming_old_leads = Lead.where(phone1: incoming_sources).or(where(phone2: incoming_sources)).to_a

        call_leads.map do |incoming_call|
          next if incoming_old_leads.any?{|ol| [ol.phone1, ol.phone2].compact.include?(incoming_call.src)}

          property = incoming_properties_numbers.
            select{|ipn| ipn[1].include?(incoming_call.did)}.first.try(:first)
          next unless property.present?

          first_name, last_name = incoming_call.cnam.split(' ')
          notes = "Incoming Call from %s (%s) at %s [CDR:%s]" % [incoming_call.cnam, incoming_call.src, incoming_call.calldate, incoming_call.id]
          referral = property.name_for_phone_number(incoming_call.did) || 'Call'

          Lead.new(
            property: property,
            source: default_source,
            referral: referral,
            phone1: incoming_call.src,
            first_name: first_name,
            last_name: last_name,
            notes: notes,
            priority: 'high',
            first_comm: incoming_call.calldate,
            last_comm: incoming_call.calldate,
            preference: LeadPreference.new
          )
        end.compact
      end

    end

  end
end
