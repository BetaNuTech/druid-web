class HomeController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :messaging_preferences, :unsubscribe]

  def dashboard
    authorize User, policy_class: HomePolicy
    @page_title = "Bluesky Dashboard"

    @my_leads = Lead.for_agent(current_user).in_progress.is_lead
    @open_leads = current_user.available_leads.includes(:property)
    @today_actions = ScheduledAction.includes(:schedule, :lead_action, :target).for_agent(current_user).due_today.sorted_by_due_asc
    @upcoming_actions = ScheduledAction.includes(:schedule, :lead_action).for_agent(current_user).upcoming.sorted_by_due_asc
    @limit_leads = [ ( params[:limit_leads] || 5 ).to_i,  @open_leads.count ].min
  end

  def manager_dashboard
    authorize User, policy_class: HomePolicy
    @page_title = "Manager Dashboard"
  end

  def messaging_preferences
    authorize User, policy_class: HomePolicy
    @page = "Update Messaging Preferences"
    @lead = Lead.where(id: params[:id]).first
  end

  def unsubscribe
    authorize User, policy_class: HomePolicy
    @page = "Update Messaging Preferences"
    lead_id = params[:lead_id]
    email_optout = params[:lead_email_optout]
    sms_optout = params[:lead_sms_optout]
    @lead = Lead.find(lead_id)
    if email_optout == "true"
      @lead.optout_email!
    else
      @lead.optin_email!
    end
    if sms_optout == "true"
      @lead.optout_sms!
    else
      @lead.optin_sms!
    end
  end

  def insert_unclaimed_lead
    authorize User, policy_class: HomePolicy
    @lead = current_user.available_leads.find(params[:id])
  end

  def impersonate
    @target_user = User.find(params[:id])
    authorize @target_user

    impersonate_user(@target_user)
    redirect_to root_path
  end

  def end_impersonation
    terminate_impersonation
    redirect_to root_path
  end

end
