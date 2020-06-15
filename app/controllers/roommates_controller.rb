class RoommatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_and_authorize_lead
  before_action :set_roommate, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  #def index
    #authorize Roommate
    #@roommates = @lead.roommates
  #end

  def new
    @roommate = @lead.roommates.build
    authorize @roommate
  end

  def create
    @roommate = @lead.roommates.build(roommate_params)
    authorize @roommate
    respond_to do |format|
      if @roommate.save
        format.html { redirect_to @lead, notice: 'Roommate added.'}
      else
        format.html { render :new }
      end
    end
  end

  #def show
    #authorize @roommate
    #redirect_to @lead
  #end

  def edit
    authorize @roommate
  end

  def update
    authorize @roommate
    respond_to do |format|
      if @roommate.update(roommate_params)
        format.html { redirect_to @lead, notice: 'Roommate record updated'}
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    authorize @roommate
    lead = @roommate.lead
    @roommate.destroy
    respond_to do |format|
      format.html { redirect_to lead, notice: 'Roommate record deleted'}
    end
  end

  private

  def record_scope
    return policy_scope(@lead.roommates)
  end

  def set_roommate
    @roommate = record_scope.find(params[:id])
  end

  def set_lead
    @lead ||= policy_scope(Lead).find(params[:lead_id])
  end

  def set_and_authorize_lead
    authorize(set_lead)
  end

  def roommate_params
    allowed_params = policy(@roommate||Roommate).allowed_params
    params.require(:roommate).permit(*allowed_params)
  end
end
