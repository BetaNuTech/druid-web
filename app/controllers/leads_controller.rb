class LeadsController < ApplicationController
  #include LeadsHelper

  before_action :authenticate_user!
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :call_log_partial, :trigger_state_event, :mark_messages_read, :progress_state, :update_state, :update_referrable_options]
  before_action :conditional_redirect_to_default_search, only: [:index, :search]
  after_action :verify_authorized

  # GET /leads
  # GET /leads.json
  def index
    # authorization performed by conditional_redirect_to_default_search
    @search = LeadSearch.new(params[:lead_search], policy_scope(Lead), current_user)
    @leads = @search.paginated
  end

  def search
    # authorization performed by conditional_redirect_to_default_search
    @search = LeadSearch.new(params[:lead_search], policy_scope(Lead), current_user)
    @webpack = 'lead_search'
    respond_to do |format|
      format.html
      format.json
      format.csv {
        filename = DateTime.now.strftime("leads-%Y-%m-%d-%H%M.csv")
        send_data @search.collection.export_csv, filename: filename
      }
    end
  end

  def mass_assignment
    authorize Lead
    page = ( params[:page] || 1 ).to_i
    @assigner = Leads::AgentAssigner.new(
      user: current_user,
      property: current_property,
      page: page
    )
  end

  def mass_assign
    authorize Lead
    assignments = params[:assignments] || []

    @assigner = Leads::AgentAssigner.new(
      user: current_user,
      property: current_property,
      assignments: assignments)

    if @assigner.call
      render :mass_assignment, notice: "#{@assigner.assignments.count} Leads have been assigned to Agents"
    else
      render :mass_assignment, notice: 'There were problems assigning Leads'
    end
  end

  # GET /leads/1
  # GET /leads/1.json
  def show
    authorize @lead
  end

  # GET /leads/new
  def new
    @lead = Lead.new
    @lead.build_preference
    @lead.user ||= current_user
    @lead.property ||= @property if @property.present?
    @lead.source ||= LeadSource.default
    authorize @lead
  end

  # GET /leads/1/edit
  def edit
    authorize @lead
    @lead.build_preference unless @lead.preference.present?
  end

  # POST /leads
  # POST /leads.json
  def create
    authorize Lead
    set_lead_source
    assign_user = lead_params['user_id'].present? ? User.find(lead_params['user_id']) : nil
    lead_creator = Leads::Creator.new(data: lead_params, agent: assign_user, token: @lead_source.api_token)
    @lead = lead_creator.call

    respond_to do |format|
      if !@lead.errors.any?
        @lead.trigger_event(event_name: 'claim', user: assign_user) if assign_user.present?
        format.html { redirect_to @lead, notice: 'Lead was successfully created.' }
        format.json { render :show, status: :created, location: @lead }
      else
        @lead.build_preference unless @lead.preference.present?
        format.html { render :new }
        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /leads/1
  # PATCH/PUT /leads/1.json
  def update
    authorize @lead
    respond_to do |format|
      if @lead.update(lead_params)
        format.html { redirect_to @lead, notice: 'Lead was successfully updated.' }
        format.json { render :show, status: :ok, location: @lead }
      else
        format.html { render :edit }
        format.json { render json: @lead.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leads/1
  # DELETE /leads/1.json
  def destroy
    authorize @lead
    @lead.destroy
    respond_to do |format|
      format.html { redirect_to leads_url, notice: 'Lead was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def trigger_state_event
    authorize @lead
    @lead.transition_memo = params[:memo] if params[:memo].present?
    @lead.classification = params[:classification] if params[:classification].present?
    @success = trigger_lead_state_event(lead: @lead, event_name: params[:eventid])
    respond_to do |format|
      format.js
      format.json { render :show, status: :ok, location: @lead }
      format.html { redirect_to(@lead)}
    end
  end

  def progress_state
    authorize @lead
    @eventid = params[:eventid]
    if @eventid == 'claim'
      trigger_lead_state_event(lead: @lead, event_name: @eventid)
      redirect_to(@lead)
    end
  end

  def update_state
    authorize @lead
    params.permit!
    @lead.transition_memo = params[:memo] if params[:memo].present?
    @lead.classification = params[:classification] if params[:classification].present?
    @lead.follow_up_at = DateTime.new(*(params[:follow_up_at].values.map(&:to_i))) if params[:follow_up_at].present?
    @success = trigger_lead_state_event(lead: @lead, event_name: params[:eventid])
    redirect_to(@lead)
  end



  def mark_messages_read
    authorize @lead
    Message.mark_read!(@lead.messages, current_user)
    redirect_to(@lead, notice: 'All Messages marked as read')
  end

  def call_log_partial
    authorize @lead
    if @lead.should_update_call_log?
      @lead.update_call_log
    end
    respond_to do |format|
      format.js
    end
  end

  def update_referrable_options
    authorize @lead
    @referral = params[:referral]
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lead
      @lead = Lead.find(params[:id])
    end

    def set_lead_source
      lead_source_id = lead_params[:lead_source_id]
      if lead_source_id.present?
        @lead_source = LeadSource.active.find(lead_source_id)
      else
        @lead_source = LeadSource.default
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lead_params
      allowed_params = policy(@lead||Lead).allowed_params
      params.require(:lead).permit(*allowed_params)
    end

    def lead_search_params
      if params[:lead_search]&.to_h&.keys&.any?
        return params[:lead_search]
      else
        return { lead_search: search_defaults }
      end
    end

    def search_defaults
      defaults = { states: Lead::PENDING_STATES }
      if current_user.property.present?
        defaults.merge!({property_ids: current_user.properties.map(&:id)})
      end
      return defaults
    end

    def default_search_url
      "/leads/search?" + lead_search_params.to_query
    end

    def redirect_to_default_search?
      params.permit!
      return params[:lead_search]&.to_h.nil?
    end

    def conditional_redirect_to_default_search
      authorize Lead
      if redirect_to_default_search?
        redirect_to default_search_url
      else
        return true
      end
    end

    def trigger_lead_state_event(lead:, event_name:)
      success = false
      if policy(lead).allow_state_event_by_user?(event_name)
        success = lead.trigger_event(event_name: event_name, user: current_user)
      end
      return success
    end
end
