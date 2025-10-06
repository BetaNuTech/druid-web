class LeadsController < ApplicationController
  #include LeadsHelper

  before_action :authenticate_user!
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :call_log_partial, :trigger_state_event, :mark_messages_read, :progress_state, :update_state, :update_referrable_options, :resend_sms_opt_in_message, :update_from_remote]
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
        filename = DateTime.current.strftime("leads-%Y-%m-%d-%H%M.csv")
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
    note_scope = NotePolicy::Scope.new(current_user, @lead.comments).resolve
    @lead_comments = note_scope.agent.comments
    @lead_timeline = note_scope.timeline
  end

  # GET /leads/new
  def new
    @lead = Lead.new
    @lead.build_preference
    @lead.user ||= current_user
    @lead.property ||= @property if @property.present?
    @lead.source ||= LeadSource.default
    @entry_type = params[:entry] || :default
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
    @entry_type = params[:entry] || :default
    assigned_agent = lead_params['user_id'].present? ? User.find(lead_params['user_id']) : @current_user
    service_data = lead_params.merge(entry_type: @entry_type)
    service = Leads::Creator.new(data: service_data, agent: assigned_agent, token: @lead_source.api_token)
    @lead = service.call

    respond_to do |format|
      if !@lead.errors.any?
        @lead.trigger_event(event_name: 'work', user: assigned_agent) if assigned_agent.present?
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
    event_name = map_legacy_event_name(params[:eventid])
    @success = trigger_lead_state_event(lead: @lead, event_name: event_name)
    respond_to do |format|
      format.js
      format.json { render :show, status: :ok, location: @lead }
      format.html { redirect_to(@lead)}
    end
  end

  def progress_state
    authorize @lead
    @eventid = map_legacy_event_name(params[:eventid])
    if @eventid == 'work'
      trigger_lead_state_event(lead: @lead, event_name: @eventid)
      redirect_to(@lead)
    end
  end

  def update_state
    authorize @lead
    params.permit!
    @lead.transition_memo = params[:memo] if params[:memo].present?
    @lead.classification = params[:classification] if params[:classification].present?

    event_name = map_legacy_event_name(params[:eventid])

    # Handle nurture follow-up date with validation
    if (event_name == 'nurture' || event_name == 'postpone') && params[:follow_up_at].present?
      begin
        # date_select returns params with keys: "(1i)" => year, "(2i)" => month, "(3i)" => day
        year = params[:follow_up_at]["(1i)"].to_i
        month = params[:follow_up_at]["(2i)"].to_i
        day = params[:follow_up_at]["(3i)"].to_i

        follow_up_date = Date.new(year, month, day)
        min_date = Date.current + 90.days
        max_date = Date.current + 275.days

        # Validate the date is within allowed range
        if follow_up_date < min_date || follow_up_date > max_date
          flash[:alert] = "Follow-up date must be between #{min_date.strftime('%B %d, %Y')} and #{max_date.strftime('%B %d, %Y')} (90-275 days from today). You selected #{follow_up_date.strftime('%B %d, %Y')}."
          redirect_to(progress_state_lead_path(@lead, eventid: event_name)) and return
        end

        # Set follow_up_at to 8am NYC time (Eastern Time)
        @lead.follow_up_at = follow_up_date.in_time_zone('America/New_York').change(hour: 8)
      rescue => e
        Rails.logger.error("Error parsing nurture follow_up_at date: #{e.message}")
        # Default to 90 days from now at 8am NYC time
        @lead.follow_up_at = (Date.current + 90.days).in_time_zone('America/New_York').change(hour: 8)
      end
    end

    @success = trigger_lead_state_event(lead: @lead, event_name: event_name)
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

  def resend_sms_opt_in_message
    authorize @lead
    if @lead.resend_opt_in_message?
      @lead.request_sms_communication_authorization(force: true)
      redirect_to @lead, notice: 'SMS Opt-In Request was re-sent'
    else
      redirect_to @lead, notice: 'SMS Opt-In Request could not be re-sent'
    end
  end

  def update_from_remote
    authorize @lead
    if @lead.update_from_remote!
      notice = "Lead updated from #{@lead.source.name}"
    else
      notice = "Lead could not be updated from #{@lead.source.name}"
    end
    redirect_to @lead, notice: notice
  end

  # GET /leads/status_dhasboard
  # Display the status of active leads for the current property
  def status_dashboard
    authorize Lead
    if @current_property.present?
      # First get the leads with user associations
      @leads = @current_property.leads
        .includes({user: :profile})
        .where(state: ['prospect', 'showing'])
        .order("user_profiles.last_name ASC, user_profiles.first_name ASC, leads.last_name ASC, leads.first_name ASC")
      
      # Preload all relevant messages and comments to avoid N+1 queries
      lead_ids = @leads.map(&:id)
      
      # Get all outgoing default messages for these leads
      all_messages = Message.outgoing
        .where(messageable_type: 'Lead', messageable_id: lead_ids, classification: 'default')
        .order(delivered_at: :desc)
      
      # Get all comments for these leads  
      all_comments = Note
        .where(notable_type: 'Lead', notable_id: lead_ids, classification: 'comment')
        .order(created_at: :desc)
      
      # Group and get latest message per lead
      @latest_messages = {}
      all_messages.each do |message|
        @latest_messages[message.messageable_id] ||= message
      end
      
      # Group and get latest 3 comments per lead
      @latest_comments = {}
      all_comments.each do |comment|
        @latest_comments[comment.notable_id] ||= []
        @latest_comments[comment.notable_id] << comment if @latest_comments[comment.notable_id].size < 3
      end
    else
      @leads = Lead.where("1=0") # return empty set if there is no current property
      @latest_messages = {}
      @latest_comments = {}
    end
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
      if @current_property
        defaults.merge!({property_ids: [@current_property.id]})
      elsif current_user.property.present?
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

    # Map legacy event names to new ones for backward compatibility
    def map_legacy_event_name(event_name)
      mapping = {
        'claim' => 'work',
        'disqualify' => 'invalidate',
        'requalify' => 'validate',
        'postpone' => 'nurture',
        'abandon' => 'nurture' # Redirect abandon to nurture
      }
      mapping[event_name] || event_name
    end
end
