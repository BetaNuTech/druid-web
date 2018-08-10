class StatsController < ApplicationController
  before_action :authenticate_user!
  after_action :verify_authorized

  def manager
    authorize Stat
    @webpack = 'dashboard'
    @stats = Stat.new(
      user: current_user,
      filters: {
        users: params[:user_ids],
        properties: params[:property_ids]
      })
  end

end
