class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  private

  def validate_token
    @source = false
    if api_token.present?
      @source = LeadSource.from_token(api_token)
    end
    if @source.present?
      return true
    else
      render json: {errors: {base: [ 'Invalid Access Token' ]}}, status: :forbidden
    end
  end

  def api_token
    params[:token] || nil
  end

end
