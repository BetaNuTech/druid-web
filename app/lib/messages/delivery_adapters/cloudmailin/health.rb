module Messages
  module DeliveryAdapters
    module Cloudmailin
      class Health

        class ServiceError < StandardError; end

        MESSAGE_STATUS_URL_KEY = 'CLOUDMAILIN_STATUS_MESSAGES_URL'
        LEAD_STATUS_URL_KEY = 'CLOUDMAILIN_STATUS_LEADS_URL'
        CLOUDMAILIN_USERNAME_KEY = 'CLOUDMAILIN_USERNAME'
        CLOUDMAILIN_PASSWORD_KEY = 'CLOUDMAILIN_PASSWORD'

        def self.messages_status_url
        end

        def self.leads_status_url
          ENV.fetch(LEAD_STATUS_URL_KEY, '')
        end

        attr_reader :window

        def initialize(window: 1.hour, threshold: 0.05)
          @window = window
          @end_time = DateTime.current
          @start_time = @end_time - @window
          @threshold = threshold
          @messages_url = ENV.fetch(MESSAGE_STATUS_URL_KEY, nil) or raise "Missing ENV #{MESSAGE_STATUS_URL_KEY}"
          @leads_url = ENV.fetch(LEAD_STATUS_URL_KEY, nil) or raise "Missing ENV #{LEAD_STATUS_URL_KEY}"
          @password = ENV.fetch(CLOUDMAILIN_PASSWORD_KEY, nil) or raise "Missing ENV #{CLOUDMAILIN_PASSWORD_KEY}"
          @username = ENV.fetch(CLOUDMAILIN_USERNAME_KEY, nil) or raise "Missing ENV #{CLOUDMAILIN_USERNAME_KEY}"
        end

        def call
          st = status

          if st[:incoming_leads][:alert] || st[:incoming_messages][:alert]
            message = 'Cloudmailin delivery success rate is below threshold'
            err = ServiceError.new(message)
            ErrorNotification.send(err, st.to_json)
            Rails.logger.error message
          else
            message = 'Cloudmailin delivery success rate is OK'
            Rails.logger.warn message
          end

          st
        end

        def status
          {
            window: @window.to_i,
            start_time: @start_time,
            end_time: @end_time,
            incoming_leads: parse_status(fetch_status(:leads)),
            incoming_messages: parse_status(fetch_status(:messages))
          }
        end

        private


        def fetch_status(endpoint)
          case endpoint
          when :messages
            url = @messages_url
          when :leads
            url = @leads_url
          end
          res = HTTParty.get(url, basic_auth: {username: @username, password: @password})
          res.body
        end

        def parse_status(json)
          json_data = JSON.parse json, symbolize_names: true
          status_data = json_data.inject({}) do |memo, obj|
            timestamp = Time.parse(obj[:created_at])
            memo[:failures] ||= {}
            memo[:total] ||= 0
            memo[:succeeded] ||= 0
            memo[:failed] ||= 0
            if timestamp > @start_time
              message_id = obj[:message_id]
              status = obj[:status].match(/^2../) ? true : false
              property = obj[:to].match(/\+([^@]+)/)[1]
              sender = obj[:from].match(/\.([^\.]+\....)$/)[1] rescue obj[:from]
              memo[:total] += 1
              if status
                memo[:succeeded] += 1
              else
                memo[:failed] += 1
                memo[:failures][property] ||= []
                memo[:failures][property] << obj
              end
            end
            memo
          end
          alert_status = ( status_data[:failed].to_f / status_data[:total].to_f ) > @threshold
          status_data[:alert] = alert_status
          status_data
        end
      end
    end
  end
end
