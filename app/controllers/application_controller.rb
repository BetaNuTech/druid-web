class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def self.http_auth_credentials
    return { name: ENV.fetch('HTTP_AUTH_NAME', 'druid'), password: ENV.fetch('HTTP_AUTH_PASSWORD', 'Default Password') }
  end
end
