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

        def request_body(params)
          template_vars = config.merge(params)
          return request_template % template_vars
        end

        def request_template
          # STUB
          ""
        end

        def getXML(options)
          url = "%{api_root}/%{resource}" % {api_root: api_root, resource: options[:resource]}
          body = request_body(options)
          headers = request_headers(method: options[:method], content_length: body.length)

          puts " * Request URL:\n" + url if @debug
          puts " * Request Headers:\n" + headers.to_a.map{|h| "#{h[0]}: #{h[1]}"}.join("\n") if @debug
          puts " * Request Body:\n" + body if @debug
          result = fetch_xml(url: url, body: body, headers: headers)
          puts " * Response:\n" + result.to_s if @debug
          return result
        end

        def fetch_xml(url:, body:, headers: {}, options: {})
          return HTTParty.post(url, body: body, headers: headers)
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
