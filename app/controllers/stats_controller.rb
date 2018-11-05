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
    @stats = Stat.new(filters: @filters, url: stats_manager_path(format: :json))
  end

end
