class ApplicationController < ActionController::Base
  include Pundit
  include ApplicationHelper
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

  def impersonate_user(user)
    allowed = policy(user).impersonate?
    ErrorNotification.send(StandardError.new("Impersonation Event"), {current_user: current_user, target_user: user, allowed: allowed, datetime: DateTime.now, action: 'start' } )
    return false unless allowed
    @true_current_user ||= current_user
    cookies.encrypted[:true_current_user_id] = true_current_user.id
    sign_out
    sign_in(:user, user)
    return true
  end

  def terminate_impersonation
    ErrorNotification.send(StandardError.new("Impersonation Event"), {current_user: current_user, target_user: true_current_user, allowed: true, datetime: DateTime.now, action: 'stop' } )
    if true_current_user.present?
      sign_out
      @true_current_user = nil
      cookies.encrypted[:true_current_user_id] = nil
    else
      return false
    end
  end


end
