class StatsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def manager
    authorize Stat
    @webpack = 'dashboard'
    @stats = Stat.new(
      user: current_user,
      filters: {
        user_ids: params[:user_ids],
        property_ids: params[:property_ids]
      })
  end

end
