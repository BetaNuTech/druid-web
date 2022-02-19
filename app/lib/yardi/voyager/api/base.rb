module Yardi
  module Voyager
    module Api
      class Base
        include HTTParty
        attr_accessor :configuration, :debug

        # Initialize with an optional Yardi::Voyager::Configuration instance
        def initialize(conf=nil)
          @debug = false
          @configuration = conf || Yardi::Voyager::Api::Configuration.new(:env)
          @request_id = nil
        end

        def request_headers(method:, content_length:, service:)
          {
            'Content-Type' => 'text/xml; charset=utf-8',
            'Content-Length' => content_length.to_s,
            'SOAPAction' => ( "http://%{host}/YSI.Interfaces.WebServices/%{service}/%{method}" %
                             {host: 'tempuri.org', method: method, service: service} )
          }
        end

        def request_body(options)
          template_vars = config.merge(options)
          return request_template(options[:method]) % template_vars
        end

        def request_template(method=nil)
          # STUB
          case method
          when 'stub'
            template_stub
          else
            template_stub
          end
        end

        def template_stub
          body_template = ""

          # Remove all line-feeds. Line-feeds kill the server for some reason.
          body_template = body_template.gsub(/[\n\r]+/,'')

          return body_template
        end

        def getData(options, dry_run: false)
          url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
          body = request_body(options)
          headers = request_headers(method: options[:method], service: options[:service], content_length: body.length)

          if @debug
            msg = " * Request URL:\n" + url
            puts msg
            Rails.logger.debug msg
            msg =  " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n")
            puts msg
            Rails.logger.debug msg
            msg = " * Request Body:\n" + body
            puts msg
            Rails.logger.debug msg
          end
          if dry_run
            result = 'Dry Run: no request sent'
          else
            result = fetch_data(url: url, body: body, headers: headers)
          end
          if @debug
            msg = " * Response:\n" + result.to_s
            puts msg
            Rails.logger.debug msg
          end
          return result
        end

        def fetch_data(url:, body:, headers: {}, options: {})
          @request_id = Digest::SHA1.hexdigest(rand(DateTime.current.to_i).to_s)[0..11]
          data = nil
          retries = 0
          begin
            start_time = DateTime.current
            Rails.logger.warn "Yardi::Voyager::Api Requesting Data at #{url}, Action #{headers['SOAPAction']} #{format_request_id}"
            data = HTTParty.post(url, body: body, headers: headers)
            elapsed = ( DateTime.current - start_time ).round(2)
            Rails.logger.warn "Yardi::Voyager::Api Completed request in #{elapsed}s #{format_request_id} "
          rescue Net::ReadTimeout => e
            if retries < 3
              retries += 1
              msg = "Yardi::Voyager::Api encountered a timeout fetching data from #{url}. Retry #{retries} of 3 #{format_request_id}"
              Rails.logger.error msg
              sleep(5)
              retry
            else
              msg = "Yardi::Voyager::Api giving up fetching data from #{url} #{format_request_id}"
              Rails.logger.error msg
              ErrorNotification.send(StandardError.new(msg))
              raise e
            end
          end
          return data
        end

        def config
          return @configuration.to_h
        end

        def api_root
          return "https://%{host}/%{webshare}/Webservices" % config
        end

        def format_request_id
          return "[Request ID: #{@request_id}]"
        end

        def create_event_note(propertyid:, incoming:, notable: nil, message: nil, error: false)
          lead_action_name = incoming ? 'Sync from Remote' : 'Sync to Remote'
          reason_name = 'Data Sync'
          classification = error ? 'error' : 'external'

          lead_action = LeadAction.where(name: lead_action_name).first
          reason = Reason.where(name: reason_name).first
          notable = notable || Leads::Adapters::YardiVoyager.property(propertyid)
          content = message
          Note.create(
            classification: classification,
            lead_action: lead_action,
            reason: reason,
            notable: notable,
            content: content,
          )
        end

      end
    end
  end
end
