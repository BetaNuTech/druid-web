module Cdrs
  module Replication
    extend ActiveSupport::Concern

    class ReplicationError < StandardError; end

    class_methods do

      ### Database Health


      def replication_status
        begin
          result = self.connection.execute('SHOW SLAVE STATUS')
          return Hash[result.fields.zip(result.to_a.first)]
        rescue
          return false
        end
      end

      def replication_ok?(status=nil)
        status = self.replication_status if status.nil?
        return false unless status
        kpis = {
          "Slave_IO_State" => status["Slave_IO_State"] == "Waiting for master to send event",
          'Slave_IO_Running' => status["Slave_IO_Running"] == "Yes",
          'Slave_SQL_Running' => status["Slave_SQL_Running"] == "Yes"
        }
        return kpis.values.all?{|v| v}
      end

      def replication_is_current?(status=nil)
        status = self.replication_status if status.nil?
        return false unless status
        kpis = {
          "_replication_ok" => self.replication_ok?(status),
          "Seconds_Behind_Master" => status["Seconds_Behind_Master"] || 0 < 60,
          "Slave_SQL_Running_State" => status["Slave_SQL_Running_State"] == "Slave has read all relay log; waiting for the slave I/O thread to update it",
        }
        return kpis.values.all?{|v| v}
      end

      def check_replication_status
        all_passed = true
        ts = DateTime.now.to_s
        status = self.replication_status

        checks = {
          working: self.replication_ok?(status),
          current: self.replication_is_current?(status)
        }

        checks.each_pair do |key, passed|
          id = key.to_s.upcase
          if passed
            message = "PASSED CDR DB Replication Check '#{id}' [#{ts}]"
            Rails.logger.warn message
          else
            all_passed = false
            message = "FAILED CDR DB Replication Check '#{id}' [#{ts}]"
            err = ReplicationError.new(message)
            ErrorNotification.send(err, status)
            Rails.logger.error message
          end
        end

        return all_passed
      end

    end

  end
end
