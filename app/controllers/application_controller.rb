class ApplicationController < ActionController::Base
  include Pundit
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  around_action :user_timezone, if: :current_user
  before_action :current_team, :set_property
  before_action :prepare_exception_notifier

  private

  def user_timezone(&block)
    Time.use_zone(current_user.timezone, &block)
  end

  def self.http_auth_credentials
    return { name: ENV.fetch('HTTP_AUTH_NAME', 'druid'), password: ENV.fetch('HTTP_AUTH_PASSWORD', 'Default Password') }
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to access this page or resource"
    redirect_to(request.referrer || root_url)
  end

  def set_property
    return nil unless current_user
    @property = @current_property ||= Property.where(id: (params[:property_id] || 0)).first || current_user.try(:properties).try(:first)
  end

  def current_team
    begin
      @current_team ||= current_user.present? ? current_user.team : nil
      return @current_team
    rescue
      return nil
    end
  end

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = { current_user: current_user }
  end

end
