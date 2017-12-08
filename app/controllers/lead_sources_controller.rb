class LeadSourcesController < ApplicationController
  before_action :set_lead_source, only: [:show, :edit, :update, :destroy]

  def index
    @lead_sources = LeadSource.all.order("name asc")
  end

  def show

  end

  def new
    @lead_source = LeadSource.new
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


  private

  def set_lead_source
    @lead_source = LeadSource.find(params[:id])
  end

  def lead_source_params
    params.require(:lead_source).permit(:name, :slug, :active, :incoming)
  end
end
