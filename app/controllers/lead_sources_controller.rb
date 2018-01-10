class LeadSourcesController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!
  before_action :set_lead_source, only: [:show, :edit, :update, :destroy, :reset_token]
  after_action :verify_authorized

  def index
    authorize LeadSource
    @lead_sources = LeadSource.all.order("name asc")
  end

  def show
    authorize @lead_source
  end

  def new
    @lead_source = LeadSource.new
    @lead_source.active = true
    @lead_source.incoming = true
    authorize @lead_source
  end

  def create
    @lead_source = LeadSource.new(lead_source_params)
    authorize @lead_source

    respond_to do |format|
      if @lead_source.save
        format.html { redirect_to @lead_source, notice: 'Lead source was successfully created.' }
        format.json { render :show, status: :created, location: @lead_source }
      else
        format.html { render :new }
        format.json { render json: @lead_source.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    authorize @lead_source
  end

  def update
    authorize @lead_source
    respond_to do |format|
      if @lead_source.update(lead_source_params)
        format.html { redirect_to @lead_source, notice: 'lead source was successfully updated.' }
        format.json { render :show, status: :ok, location: @lead_source }
      else
        format.html { render :edit }
        format.json { render json: @lead_source.errors, status: :unprocessable_entity }
      end
    end

  end

  def destroy
    authorize @lead_source
    @lead_source.destroy
    respond_to do |format|
      format.html { redirect_to lead_sources_url, notice: 'Lead Source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def reset_token
    authorize @lead_source
    @lead_source.api_token = nil
    @lead_source.save
    respond_to do |format|
      format.html { redirect_to @lead_source, notice: 'API Token has been reset'}
      format.json { render :show, status: :ok }
    end
  end


  private

  def set_lead_source
    @lead_source = LeadSource.find(params[:id])
  end

  def lead_source_params
    allowed_params = policy(LeadSource).allowed_params
    params.require(:lead_source).permit(*allowed_params)
  end
end
