module Leads
  module Adapters
    class Zillow
      LEAD_SOURCE_SLUG = 'Zillow'

      # Description  : Zillow Provides data as an HTTP POST callback
      # Documentation: https://hotpads.com/pages/partners/leadCallback.htm
      # Support      : rentalfeeds@zillow.com

      def initialize(params)
        @property_code = get_property_code(params)
        @data = filter_params(params)
      end

      def parse
        return build(data: map(@data), property_code: @property_code)
      end

      private


      # Convert input data Hash into Lead attributes
      #
      # Data Mapping
      #
      # |-----------------------+-------------------------|
      # | Zillow Field          | Lead Attr               |
      # |-----------------------+-------------------------|
      # | listingId             | (Property Code)         |
      # | name                  | Lead.last_name          |
      # | email                 | Lead.email              |
      # | phone                 | Lead.phone              |
      # | movingDate            | LeadPreference.move_in  |
      # | numBedroomsSought     | LeadPreference.beds     |
      # | numBathroomsSought    | LeadPreference.baths    |
      # | message               | LeadPreference.notes    |
      # | listingString         | none                    |
      # | listingUnit           | none                    |
      # | listingCity           | none                    |
      # | listingPostalCode     | none                    |
      # | listingState          | none                    |
      # | listingContactEmail   | none                    |
      # | neighborhoods         | none                    |
      # | propertyTypesDesired  | none                    |
      # | leaseLengthMonths     | none                    |
      # | introduction          | LeadPreference.notes    |
      # | smoker                | LeadPrefererence.smoker |
      # | parkingTypesDesired   | none                    |
      # | incomeYearly          | none                    |
      # | creditScoreRangeJson  | none                    |
      # | movingFromCity        | none                    |
      # | movingFromState       | none                    |
      # | moveInTimeframe       | none                    |
      # | reasonForMoving       | none                    |
      # | employmentStatus      | none                    |
      # | jobTitle              | none                    |
      # | employer              | none                    |
      # | employmentStartDate   | none                    |
      # | employmentDetailsJson | none                    |
      # | petDetailsJson        | none                    |
      # |-----------------------+-------------------------|
      #
      def map(data)
        return {
          title: '',
          first_name: data[:name] || '(not provided)',
          last_name: '',
          referral: nil,
          phone1: data[:phone],
          phone2: nil,
          email: data[:email],
          fax: nil,
          preference_attributes: {
						baths: data[:numBathroomsSought],
						beds: data[:numBedroomsSought],
						notes: ( data[:introduction] || '' ) + ( data[:message] || '' ),
						smoker: data[:smoker],
            raw_data: data.to_json,
            pets: !(JSON.parse(data[:petDetailsJson] || '')).empty?
          }
        }
      end

      def build(data:, property_code:)
        lead = Lead.new(data)
        lead.validate
        status = lead.valid? ? :ok : :invalid
        result = Leads::Creator::Result.new( status: status, lead: data, errors: lead.errors, property_code: property_code)
        return result
      end

      def get_property_code(params)
        return params[:listingId]
      end

      def filter_params(params)
        # STUB
        return params
      end

    end
  end
end
