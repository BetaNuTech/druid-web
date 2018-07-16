module Leads
  module CallLog
    extend ActiveSupport::Concern

    included do

      CALL_LOG_FREQUENCY = 10 # minutes

      scope :recent_recordings, -> (start_time=1.week.ago) {
        phone_numbers = self.all.map{|l| [l.phone1, l.phone2]}.flatten.compact.uniq
        return Cdr.where('calldate >= ? AND recordingfile IS NOT NULL', start_time).
          calls_for(phone_numbers)
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

  end
end
