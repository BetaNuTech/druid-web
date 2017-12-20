class ApiController < ApplicationController

  private

  def validate_token
    if api_token.present?
      @source = LeadSource.active.where(api_token: api_token).first
    else
      @source = false
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
