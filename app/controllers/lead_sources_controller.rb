class LeadSourcesController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!
  before_action :set_lead_source, only: [:show, :edit, :update, :destroy, :reset_token]

  def index
    @lead_sources = LeadSource.all.order("name asc")
  end

  def show

  end

  def new
    @lead_source = LeadSource.new
    @lead_source.active = true
    @lead_source.incoming = true
  end

  def create
    @lead_source = LeadSource.new(lead_source_params)

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

  end

  def update
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
    @lead_source.destroy
    respond_to do |format|
      format.html { redirect_to lead_sources_url, notice: 'Lead Source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def reset_token
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
    params.require(:lead_source).permit(:name, :slug, :active, :incoming)
  end
end
