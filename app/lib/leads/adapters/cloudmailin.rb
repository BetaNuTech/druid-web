module Leads
  module Adapters
    class Cloudmailin
      # Input data is assumed to follow the CloudMailin multi-part post format
      #
      # See: http://docs.cloudmailin.com/http_post_formats/multipart/
      #

      LEAD_SOURCE_SLUG = 'Cloudmailin'

      class Parser
        attr_reader :parser, :data

        class RentDotCom
          def self.match?(data)
            (data.fetch(:plain, nil) || data.fetch(:html,nil) || '').match?('Rent.com').present?
          end

          def self.parse(data)
            body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''
          end
        end

        class NullParser

          def self.match?(data)
            true
          end

          def self.parse(data)
            return {
              title: 'Null',
              first_name: 'Null',
              last_name: 'Null',
              referral: nil,
              phone1: 'Null',
              phone2: 'Null',
              email: 'Null',
              fax: 'Null',
              preference_attributes: {
                baths: 'Null',
                beds: 'Null',
                notes: 'Null',
                smoker: 'Null',
                raw_data: data.to_json,
                pets: false
              }
            }
          end
        end

        PARSERS = [RentDotCom]

        def initialize(data)
          @data = data
          @parser = detect_source(@data)
        end

        def parse
          @parser.parse(@data)
        end

        private

        def detect_source(data)
          PARSERS.detect{|p| p.match?(data)} || NullParser
        end

      end

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: extract(@data), property_code: @property_code)
      end

      private

      def map(data)
        Rails.logger.warn data.inspect
        return {
          title: '',
          first_name: '' || '(not provided)' ,
          last_name: '',
          referral: nil,
          phone1: '',
          phone2: nil,
          email: '',
          fax: nil,
          preference_attributes: {
						baths: '',
						beds: '',
						notes: '',
						smoker: '',
            raw_data: data.to_json,
            pets: false
          }
        }
      end

      def extract(data)
        Parser.new(data).parse
      end


      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        status = lead.valid? ? :ok : :invalid

        result = Leads::Creator::Result.new( status: status, lead: data, errors: lead.errors, property_code: property_code)

        return result
      end

      def get_property_code(params)
        to_addr = params.fetch(:envelope, {}).fetch(:to,'') || ""
        code = ( to_addr.split('@').first || "" ).split("+").last
        return code
      end

      def filter_params(params)
        # STUB
        return params
      end

      def sanitize(value)
        return ActionController::Base.helpers.sanitize(value)
      end
    end
  end

end
