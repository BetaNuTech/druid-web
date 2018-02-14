class LeadActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lead_action, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /lead_actions
  # GET /lead_actions.json
  def index
    authorize LeadAction
    @lead_actions = LeadAction.order(name: "ASC")
  end

  # GET /lead_actions/1
  # GET /lead_actions/1.json
  def show
    authorize @lead_action
  end

  # GET /lead_actions/new
  def new
    @lead_action = LeadAction.new
    authorize @lead_action
  end

  # GET /lead_actions/1/edit
  def edit
    authorize @lead_action
  end

  # POST /lead_actions
  # POST /lead_actions.json
  def create
    @lead_action = LeadAction.new(lead_action_params)
    authorize @lead_action

    respond_to do |format|
      if @lead_action.save
        format.html { redirect_to @lead_action, notice: 'Lead action was successfully created.' }
        format.json { render :show, status: :created, location: @lead_action }
      else
        format.html { render :new }
        format.json { render json: @lead_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lead_actions/1
  # PATCH/PUT /lead_actions/1.json
  def update
    authorize @lead_action
    respond_to do |format|
      if @lead_action.update(lead_action_params)
        format.html { redirect_to @lead_action, notice: 'Lead action was successfully updated.' }
        format.json { render :show, status: :ok, location: @lead_action }
      else
        format.html { render :edit }
        format.json { render json: @lead_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lead_actions/1
  # DELETE /lead_actions/1.json
  def destroy
    authorize @lead_action
    @lead_action.destroy
    respond_to do |format|
      format.html { redirect_to lead_actions_url, notice: 'Lead action was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_lead_action
      @lead_action = LeadAction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lead_action_params
      params.require(:lead_action).permit(policy(LeadAction).allowed_params)
    end
end
