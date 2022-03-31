module Api
  module V1
    class LeadsController < ApiController
      before_action :validate_lead_source_token

      # GET /api/v1/leads.json?token=XXX&limit=XXX
      def index
        unless access_policy.index?
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        limit = (params[:limit] || 10).to_i
        @leads = @source.leads.order("created_at desc").limit(limit)

        render 'leads/index', format: :json
      end

      # POST /api/v1/leads
      def create
        unless access_policy.create?
          Leads::Creator.create_event_note(message: 'Lead API Access Denied', error: true)
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        lead_data = params
        token = params[:token]
        lead_creator = Leads::Creator.new(data: lead_data, agent: nil, token: token)
        @lead = lead_creator.call
        if @lead.valid? && @lead.id.present?
          render :create, status: :created, format: :json
        else
          render json: {errors: @lead.errors}, status: :unprocessable_entity, format: :json
        end
      end

      # Return Prospect Stats
      #
      # URL Examples:
      # (all properties): GET /api/v1/prospect_stats.json?token=XXX
      # (specified properties): GET /api/v1/prospect_stats.json?token=XXX&stats=properties&ids[]=XXX&ids[]=YYY
      # (all teams): GET /api/v1/prospect_stats.json?token=XXX&stats=teams
      # (all agents): GET /api/v1/prospect_stats.json?token=XXX&stats=agents
      def prospect_stats
        @stats_for = ( params[:stats] || 'properties' )
        @ids = params[:ids]
        unless access_policy.prospect_stats?
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end
        @stats = ProspectStats.new(ids: @ids, filters: {date: params[:date]})
      end

      def property_info
        unless access_policy.create?
          Leads::Creator.create_event_note(message: 'Lead API Access Denied', error: true)
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        render json: Property.property_info_for_incoming_number(params[:number])
      end

      
      # REQUEST: (DRAFT)
      # {
      #  "propertyId": "XXXXX",
      #  "category": "onsite-tour", // this could be the type of appointment
      #  "fromDate": "MM/DD/YYYY", // optional, default todays date
      #  "toDate": "MM/DD/YYYY". // optional, default todays date + 14 days
      # }
      #
      # RESPONSE: (DRAFT)
      # {
      #   "propertyId": "XXXXX",
      #   "appointmentLength": "45",
      #   "category": "onsite-tour",
      #   "availability": [
      #     {
      #       "date": "10/12/2021",
      #       "day": "Monday",
      #       "times": [
      #         "11:00:00MST",
      #         "12:00:00MST",
      #         "13:00:00MST",
      #         "14:00:00MST"
      #       ]
      #     },
      #     // other days with times available for onsite tours
      #   ]
      # } 

      def property_schedule_availability
        unless access_policy.property_schedule_availability?
          Leads::Creator.create_event_note(message: "Schedule API Access Denied for token #{api_token}", error: true)
          render json: {errors: {base: [ 'Access Denied' ]}}, status: :forbidden
          return
        end

        property_listing_code = params[:propertyId]
        property = PropertyListing.active.where(source: @source, code: property_listing_code).first&.property or
          raise ActiveRecord::RecordNotFound

        service_params = {
          start_time: ( DateTime.parse(params[:fromDate]) rescue Time.current ),
          end_time:  ( DateTime.parse(params[:toDate]) rescue Time.current + 14.days ).end_of_day,
          property_code: property_listing_code
        }

        render json: Property.schedule_availability(property, service_params)
      end

      private

      def validate_lead_source_token
        validate_source_token(source: LeadSource, token: api_token)
      end

      def access_policy
        LeadApiPolicy.new(nil, @source)
      end

    end
  end
end
