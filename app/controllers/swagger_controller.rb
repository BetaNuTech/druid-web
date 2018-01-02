class SwaggerController < ActionController::Base

  before_action :set_source

  def index
    # Define a LEAD_SOURCE_SLUG.json.erb containing the Swagger API definition
    render @source.slug.downcase
  end

  def apidocs
    render file: Rails.public_path.join("apidocs","index.html"), layout: false
  end

  private

  def set_source
    @source = LeadSource.from_token(params[:token])
    if @source.present?
      return true
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end
