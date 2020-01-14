class EngagementPoliciesController < ApplicationController
  #before_action :set_engagement_policy, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  after_action :verify_authorized

  # GET /engagement_policies
  # GET /engagement_policies.json
  def index
    authorize EngagementPolicy
    @engagement_policies = EngagementPolicy.latest_version
    if @property.present?
      @engagement_policies = @engagement_policies.for_property(@property.id)
    end
  end

  #private
  ## Use callbacks to share common setup or constraints between actions.
  #def set_engagement_policy
    #@engagement_policy = EngagementPolicy.find(params[:id])
  #end

  ## Never trust parameters from the scary internet, only allow the white list through.
  #def engagement_policy_params
    #params.require(:engagement_policy).permit(policy(EngagementPolicy).allowed_params)
  #end
end
