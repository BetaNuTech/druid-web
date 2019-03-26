module Yardi
  module Voyager
    module Api
      class Base
        include HTTParty
        attr_reader :configuration
        attr_accessor :debug

        # Initialize with an optional Yardi::Voyager::Configuration instance
        def initialize(conf=nil)
          @debug = false
          @configuration = conf || Yardi::Voyager::Api::Configuration.new(:env)
          @request_id = nil
        end

        def request_headers(method:, content_length:)
          {
            'Content-Type' => 'text/xml; charset=utf-8',
            'Content-Length' => content_length.to_s,
            'SOAPAction' => ( "http://%{host}/YSI.Interfaces.WebServices/ItfILSGuestCard/%{method}" %
                             {host: 'tempuri.org', method: method} )
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

        def getData(options)
          url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
          body = request_body(options)
          headers = request_headers(method: options[:method], content_length: body.length)

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
          result = fetch_data(url: url, body: body, headers: headers)
          if @debug
            msg = " * Response:\n" + result.to_s
            puts msg
            Rails.logger.debug msg
          end
          return result
        end

        def fetch_data(url:, body:, headers: {}, options: {})
          @request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
          data = nil
          retries = 0
          begin
            start_time = Time.now
            Rails.logger.warn "Yardi::Voyager::Api Requesting Data at #{url}, Action #{headers['SOAPAction']} #{format_request_id}"
            data = HTTParty.post(url, body: body, headers: headers)
            elapsed = ( Time.now - start_time ).round(2)
            Rails.logger.warn "Yardi::Voyager::Api Completed request in #{elapsed}s #{format_request_id} "
          rescue Net::ReadTimeout => e
            if retries < 3
              retries += 1
              msg = "Yardi::Voyager::Api encountered a timeout fetching data from #{url}. Retry #{retries} of 3 #{format_request_id}"
              Rails.logger.error msg
              #ErrorNotification.send(StandardError.new(msg))
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

      end
    end
  end
end
