class PropertiesController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!
  before_action :set_property, only: [:show, :edit, :update, :destroy, :duplicate_leads]
  after_action :verify_authorized

  # GET /properties
  # GET /properties.json
  def index
    authorize Property
    @properties = Property.includes(:team).order("name ASC")
  end

  # GET /properties/1
  # GET /properties/1.json
  def show
    authorize @property
  end

  # GET /properties/new
  def new
    @property = Property.new
    authorize @property
    @property.phone_numbers += [ @property.phone_numbers.build(category: 'work') ]
  end

  # GET /properties/1/edit
  def edit
    authorize @property
    @property.phone_numbers += [ @property.phone_numbers.build(category: 'work') ]
  end

  # POST /properties
  # POST /properties.json
  def create
    @property = Property.new(property_params)
    authorize @property

    respond_to do |format|
      if @property.save
        format.html { redirect_to @property, notice: 'Property was successfully created.' }
        format.json { render :show, status: :created, location: @property }
      else
        format.html { render :new }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /properties/1
  # PATCH/PUT /properties/1.json
  def update
    authorize @property
    respond_to do |format|
      if @property.update(property_params)
        format.html { redirect_to @property, notice: 'Property was successfully updated.' }
        format.json { render :show, status: :ok, location: @property }
      else
        format.html { render :edit }
        format.json { render json: @property.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /properties/1
  # DELETE /properties/1.json
  def destroy
    authorize @property
    @property.destroy
    respond_to do |format|
      format.html { redirect_to properties_url, notice: 'Property was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def duplicate_leads
    authorize @property
    @grouped_duplicates = DuplicateLead.
      for_property_accessible_by_user(@property, current_user)
  end

  def select_current
    authorize Property
    @current_property = Property.find(params[:property_id])
    cookies[:current_property] = @current_property.id if @current_property
    redirect_to URI(request.referer).path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_property
      @property = policy_scope(Property).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def property_params
      valid_property_params = policy(Property).allowed_params
      params.require(:property).permit(*valid_property_params)
    end
end
