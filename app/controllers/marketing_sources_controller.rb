class MarketingSourcesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_marketing_source, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  def index
    authorize MarketingSource
    set_property_id
    @marketing_sources = marketing_source_scope.includes(:property, :marketing_expenses).
      where(property_id: @property_id).
      order('properties.name ASC, marketing_sources.name ASC')
  end

  def new
    authorize MarketingSource
    set_property_id
    integration_helper = MarketingSources::IncomingIntegrationHelper.new(property: Property.find(@property_id), integration: LeadSource.default)
    @marketing_source = MarketingSource.new(integration_helper.new_marketing_source_attributes)
  end

  def create
    @marketing_source = MarketingSource.new(marketing_source_params)
    authorize @marketing_source
    respond_to do |format|
      if @marketing_source.save
        format.html  { redirect_to marketing_sources_path + "##{@marketing_source.id}", notice: 'Marketing Source was created.', alert: call_routing_alert }
      else
        format.html { render :new }
      end
    end
  end

  def edit
    authorize @marketing_source
  end

  def update
    authorize @marketing_source
    respond_to do |format|
      if @marketing_source.update(marketing_source_params)
        format.html  { redirect_to marketing_sources_path + "##{@marketing_source.id}", notice: 'Marketing Source was updated.', alert: call_routing_alert }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    authorize @marketing_source
    @marketing_source.destroy
    respond_to do |format|
      format.html { redirect_to marketing_sources_path, notice: 'Marketing Source was deleted.' }
    end
  end

  def show
    authorize @marketing_source
  end

  def form_suggest_tracking_details
    authorize MarketingSource
    property = Property.find(params[:property_id])
    @helper = MarketingSources::IncomingIntegrationHelper.new(
      property: property,
      integration: params[:lead_source_id]
    )
    respond_to do |format|
      format.json { render json: @helper.options_for_integration }
    end
  end

  def report
    authorize MarketingSource
    @report = MarketingSources::Report.new(params[:marketing_sources_report])
    respond_to do|format|
      format.html
      format.csv  {
        send_data @report.csv, filename: @report.csv_filename
      }
    end
  end

  private

  # Warn (without blocking the save) when a tracking number was saved for a
  # property that is not set up to route and attribute the resulting calls.
  # Only :blocking issues are flashed here - the main line, which is the
  # fallback destination for the tracking number, and the CallCenter listing
  # code, without which the phone lead gets no property at all. Warnings such
  # as office hours and timezone are left to the page. See
  # Properties::CallRouting.
  def call_routing_alert
    return nil if @marketing_source.tracking_number.blank?

    property = @marketing_source.property
    issues = property&.call_routing_blocking_issues || []
    return nil if issues.empty?

    "A tracking number is set, but #{property.name} is not ready to handle the " \
      "calls: #{issues.map { |issue| issue[:message] }.join(' ')}"
  end

  def marketing_source_scope(skope=MarketingSource)
    policy_scope(skope)
  end

  def set_marketing_source
    @marketing_source ||= marketing_source_scope.find(params[:id])
  end

  def marketing_source_params
    allowed_params = policy(@marketing_source || MarketingSource).allowed_params
    params.require(:marketing_source).permit(*allowed_params)
  end

  def set_property_id
    property_id = params[:property_id] || @current_property&.id
    property_id = nil unless policy(@marketing_source || MarketingSource).allowed_properties.map(&:id).include?(property_id)
    @property_id = property_id
  end
end
