class ApplicationController < ActionController::Base
  include Pundit
  include ApplicationHelper
  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  layout -> {versioned_layout }

  before_action :create_user_impression, if: :current_user
  around_action :user_timezone, if: :current_user
  before_action :current_team
  before_action :set_property
  before_action :prepare_exception_notifier

  def versioned_layout
    if Flipflop.enabled?(:design_v1)
      'application_v1'
    else
      'application'
    end
  end

  def create_user_impression
    return true unless Flipflop.user_tracking?
    begin
      impression = URI(request.path).path rescue 'ERROR'
      referrer = URI(request.referer).path rescue 'ERROR'
      UserImpression.create(
        user_id: current_user&.id,
        reference: AppContext.for_params(params).last,
        referrer: referrer,
        path: impression
      )
    rescue => e
      Rails.logger.warn('Error creating user impression: ' + e.to_s)
      true
    end
  end

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
    property_id = params[:property_id] || cookies[:current_property] || current_user&.properties&.first || 0
    @property = @current_property = Property.where(id: property_id).first
  end

  def current_property
    begin
      @current_property ||= set_property
    rescue
      nil
    end
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
    hostname = "#{ENV.fetch('APPLICATION_DOMAIN','Unknown Domain')} (#{ENV.fetch('APPLICATION_HOST','Unknown Host')})"
    request.env["exception_notifier.exception_data"] = { current_user: current_user&.email, host: hostname  }
  end

  def impersonate_user(user)
    allowed = policy(user).impersonate?
    ErrorNotification.send(StandardError.new("Impersonation Event"), {current_user: current_user&.email, target_user: user&.email, allowed: allowed, datetime: DateTime.current, action: 'start' } )
    return false unless allowed
    @true_current_user ||= current_user
    cookies.encrypted[:true_current_user_id] = true_current_user&.id
    sign_out
    sign_in(:user, user)
    return true
  end

  def terminate_impersonation
    ErrorNotification.send(StandardError.new("Impersonation Event"), {current_user: current_user.email, target_user: true_current_user.email, allowed: true, datetime: DateTime.current, action: 'stop' } )
    if true_current_user.present?
      sign_out
      @true_current_user = nil
      cookies.encrypted[:true_current_user_id] = nil
    else
      return false
    end
  end


end
