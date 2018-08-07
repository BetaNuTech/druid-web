class HomeController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :messaging_preferences, :unsubscribe]

  def dashboard
    @page_title = "Druid Dashboard"

    @my_leads = Lead.for_agent(current_user).active
    @unclaimed_leads = current_user.available_leads
    @today_actions = ScheduledAction.includes(:schedule, :lead_action).for_agent(current_user).due_today.sorted_by_due_asc
    @upcoming_actions = ScheduledAction.includes(:schedule, :lead_action).for_agent(current_user).upcoming.sorted_by_due_asc
    @limit_leads = [ ( params[:limit_leads] || 5 ).to_i,  @unclaimed_leads.count ].min
  end

  def manager_dashboard

  end

  def messaging_preferences
    @page = "Update Messaging Preferences"
    @lead = Lead.where(id: params[:id]).first
  end

  def unsubscribe
    @page = "Update Messaging Preferences"
    lead_id = params[:lead_id]
    optout = params[:lead_optout]
    if @lead = Lead.where(id: lead_id).first
      if optout == "true"
        @lead.optout!
        flash[:notice] = "You have opted out of email notifications."
      else
        @lead.optin!
        flash[:notice] = "You may recieve email notifications again."
      end
    else
      redirect_to(messaging_preferences_path(id: :lead_id))
    end
  end
end
