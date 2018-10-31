class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  private

  def api_token
    @token ||= params[:token] || nil
  end

  def validate_source_token(source: , token:)
    @source = api_token.present? ? source.from_token(token) : false
    if @source.present? && @source.active?
      return true
    else
      render json: {errors: {base: [ 'Invalid Access Token' ]}}, status: :forbidden
    end
  end

end
