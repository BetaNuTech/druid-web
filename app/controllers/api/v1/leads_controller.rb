module Api
  module V1
    class LeadsController < ApiController
      def create
        lead_source = params[:source]
        lead_data = params[:lead]
        lead_creator = Leads::Creator.new(data: lead_data, source: lead_source, agent: nil)
        @lead = lead_creator.execute
        if @lead.valid?
          render :create, status: :created
        else
          render json: @lead.errors, status: :unprocessable_entity
        end
      end
    end
  end
end
