class StatsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def manager
    authorize Stat
    @webpack = 'dashboard'
    @filters = {
      user_ids: params[:user_ids],
      property_ids: params[:property_ids],
      team_ids: params[:team_ids],
      date_range: params[:date_range],
      timezone: params[:timezone]
    }
    @report = params[:report] || 'lead_sources'
    @stats = Stat.new(filters: @filters, url: stats_manager_path(format: :json))
  end

  def report_csv
    authorize Stat
    report = params[:report] || 'property_engagement_stats_by_month'
    report_filename = "#{report}-#{Date.current.to_s}.csv"
    service = Stat.new
    report_data = service.send((report + '_csv' ).to_sym)
    respond_to do |format|
      format.csv  {
        send_data report_data, filename: report_filename
      }
    end
  end

  def lead_engagement_csv
    authorize Stat
    options = {}
    options[:properties] = params[:property_ids] if params[:property_ids].present?
    report = params[:report] || 'lead_engagement'
    report_data = LeadEngagementReport.new(options:).generate_csv
    report_filename = "#{report}-#{Date.current.to_s}.csv"
    respond_to do |format|
      format.csv {
        send_data report_data, filename: report_filename
      }
    end
  end

  def referral_bounces
    authorize Stat
    @service = ReferralBounceService.new
  end

end
