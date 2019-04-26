class LeadReferralSourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lead_referral_source, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /lead_referral_sources
  # GET /lead_referral_sources.json
  def index
    authorize LeadReferralSource
    @lead_referral_sources = LeadReferralSource.order(name: :asc)
  end

  # GET /lead_referral_sources/1
  # GET /lead_referral_sources/1.json
  def show
    authorize @lead_referral_source
  end

  # GET /lead_referral_sources/new
  def new
    authorize LeadReferralSource
    @lead_referral_source = LeadReferralSource.new
  end

  # GET /lead_referral_sources/1/edit
  def edit
    authorize @lead_referral_source
  end

  # POST /lead_referral_sources
  # POST /lead_referral_sources.json
  def create
    @lead_referral_source = LeadReferralSource.new(lead_referral_source_params)
    authorize @lead_referral_source

    respond_to do |format|
      if @lead_referral_source.save
        format.html { redirect_to @lead_referral_source, notice: 'Lead referral source was successfully created.' }
        format.json { render :show, status: :created, location: @lead_referral_source }
      else
        format.html { render :new }
        format.json { render json: @lead_referral_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lead_referral_sources/1
  # PATCH/PUT /lead_referral_sources/1.json
  def update
    authorize @lead_referral_source
    respond_to do |format|
      if @lead_referral_source.update(lead_referral_source_params)
        format.html { redirect_to @lead_referral_source, notice: 'Lead referral source was successfully updated.' }
        format.json { render :show, status: :ok, location: @lead_referral_source }
      else
        format.html { render :edit }
        format.json { render json: @lead_referral_source.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lead_referral_sources/1
  # DELETE /lead_referral_sources/1.json
  def destroy
    authorize @lead_referral_source
    @lead_referral_source.destroy
    respond_to do |format|
      format.html { redirect_to lead_referral_sources_url, notice: 'Lead referral source was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_lead_referral_source
    @lead_referral_source = LeadReferralSource.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def lead_referral_source_params
    allowed_params = policy(@lead_referral_source||LeadReferralSource).allowed_params
    params.require(:lead_referral_source).permit(*allowed_params)
  end
end
