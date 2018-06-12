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

          puts " * Request URL:\n" + url if @debug
          puts " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n") if @debug
          puts " * Request Body:\n" + body if @debug
          result = fetch_data(url: url, body: body, headers: headers)
          puts " * Response:\n" + result.to_s if @debug
          return result
        end

        def fetch_data(url:, body:, headers: {}, options: {})
          request_id = Digest::SHA1.hexdigest(rand(Time.now.to_i).to_s)[0..11]
          data = nil
          retries = 0
          begin
            start_time = Time.now
            Rails.logger.warn "Yardi::Voyager::Api Requesting Data at #{url}, Action #{headers['SOAPAction']} [Request ID: #{request_id}]"
            data = HTTParty.post(url, body: body, headers: headers)
            elapsed = ( Time.now - start_time ).round(2)
            Rails.logger.warn "Yardi::Voyager::Api Completed request in #{elapsed}s [Request ID: #{request_id}]"
          rescue Net::ReadTimeout => e
            if retries < 3
              retries += 1
              Rails.logger.error "Yardi::Voyager::Api encountered a timeout fetching data from #{url}. Retry #{retries} of 3 [Request ID: #{request_id}]"
              sleep(5)
              retry
            else
              Rails.logger.error "Yardi::Voyager::Api giving up [Request ID: #{request_id}]"
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

      end
    end
  end
end
