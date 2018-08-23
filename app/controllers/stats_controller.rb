class StatsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def manager
    authorize Stat
    @webpack = 'dashboard'
    @filters = {
      user_ids: params[:user_ids],
      property_ids: params[:property_ids]
    }
    @stats = Stat.new(user: current_user, filters: @filters, url: stats_manager_path(format: :json))
  end

end
