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
      date_range: params[:date_range]
    }
    @report = params[:report] || 'lead_sources'
    @stats = Stat.new(filters: @filters, url: stats_manager_path(format: :json))
  end

  def report_csv
    authorize Stat
    report = params[:report] || 'property_engagement_stats_by_month'
    report_filename = "#{report}-#{Date.today.to_s}.csv"
    service = Stat.new
    report_data = service.send((report + '_csv' ).to_sym)
    respond_to do |format|
      format.csv  {
        send_data report_data, filename: report_filename
      }
    end
  end

end
