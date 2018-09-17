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
        Cdr.possible_leads.map do |incoming_call|
          Lead.new(
          
          )
        end
      end

    end

  end
end
