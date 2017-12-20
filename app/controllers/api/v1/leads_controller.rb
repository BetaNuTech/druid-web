module Api
  module V1
    class LeadsController < ApiController
      before_action :validate_token

      # GET /api/v1/leads.json?token=XXX&limit=XXX
      def index
        limit = (params[:limit] || 10).to_i
        @leads = @source.leads.order("created_at desc").limit(limit)

        render 'leads/index', format: :json
      end

      # POST /api/v1/leads
      def create
        lead_data = params
        lead_source = params[:source]
        token = params[:token]
        lead_creator = Leads::Creator.new(data: lead_data, source: lead_source, agent: nil, validate_token: token)
        @lead = lead_creator.execute
        if @lead.valid?
          render :create, status: :created, format: :json
        else
          render json: {errors: lead_creator.errors}, status: :unprocessable_entity, format: :json
        end
      end

    end
  end
end
