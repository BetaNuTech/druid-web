class LeadsController < ApplicationController
  include LeadsHelper

  before_action :authenticate_user!
  before_action :set_lead, only: [:show, :edit, :update, :destroy, :call_log_partial, :trigger_state_event, :mark_messages_read]
  after_action :verify_authorized

  # GET /leads
  # GET /leads.json
  def index
    authorize Lead
    @search = LeadSearch.new(params[:lead_search])
    @leads = @search.paginated
  end

  def search
    authorize Lead
    @search = LeadSearch.new(params[:lead_search])
    @webpack = "lead_search"
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
    #TODO assign current_user to agent
    lead_creator = Leads::Creator.new(data: lead_params, agent: nil, token: @lead_source.api_token)
    @lead = lead_creator.execute

    respond_to do |format|
      if !@lead.errors.any?
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
    @success = trigger_lead_state_event(lead: @lead, event_name: params[:eventid])
    respond_to do |format|
      format.js
      format.json { render :show, status: :ok, location: @lead }
      format.html { redirect_to(@lead)}
    end
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

end
