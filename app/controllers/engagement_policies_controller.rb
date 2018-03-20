class EngagementPoliciesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_engagement_policy, only: [:show, :edit, :update, :destroy]

  # GET /engagement_policies
  # GET /engagement_policies.json
  def index
    @engagement_policies = EngagementPolicy.all
  end

  # GET /engagement_policies/1
  # GET /engagement_policies/1.json
  def show
  end

  # GET /engagement_policies/new
  def new
    @engagement_policy = EngagementPolicy.new
  end

  # GET /engagement_policies/1/edit
  def edit
  end

  # POST /engagement_policies
  # POST /engagement_policies.json
  def create
    @engagement_policy = EngagementPolicy.new(engagement_policy_params)

    respond_to do |format|
      if @engagement_policy.save
        format.html { redirect_to @engagement_policy, notice: 'Engagement policy was successfully created.' }
        format.json { render :show, status: :created, location: @engagement_policy }
      else
        format.html { render :new }
        format.json { render json: @engagement_policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /engagement_policies/1
  # PATCH/PUT /engagement_policies/1.json
  def update
    respond_to do |format|
      if @engagement_policy.update(engagement_policy_params)
        format.html { redirect_to @engagement_policy, notice: 'Engagement policy was successfully updated.' }
        format.json { render :show, status: :ok, location: @engagement_policy }
      else
        format.html { render :edit }
        format.json { render json: @engagement_policy.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /engagement_policies/1
  # DELETE /engagement_policies/1.json
  def destroy
    @engagement_policy.destroy
    respond_to do |format|
      format.html { redirect_to engagement_policies_url, notice: 'Engagement policy was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_engagement_policy
      @engagement_policy = EngagementPolicy.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def engagement_policy_params
      params.fetch(:engagement_policy, {})
    end
end
