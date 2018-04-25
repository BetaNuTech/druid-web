class HomeController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!, except: :index

  HTTP_AUTH=true

  #def index
    #@page_title = "Druid Home"
  #end

  def dashboard
    @page_title = "Druid Dashboard"

    @my_leads = Lead.for_agent(current_user).active
    @unclaimed_leads = current_user.available_leads.limit(10)
    @today_actions = ScheduledAction.for_agent(current_user).due_today.sorted_by_due_asc
    @upcoming_actions = ScheduledAction.for_agent(current_user).upcoming.sorted_by_due_asc
  end
end
