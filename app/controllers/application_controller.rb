class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def self.http_auth_credentials
    return { name: ENV.fetch('HTTP_AUTH_NAME', 'druid'), password: ENV.fetch('HTTP_AUTH_PASSWORD', 'Default Password') }
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to access this page or resource"
    redirect_to(request.referrer || root_url)
  end
end
