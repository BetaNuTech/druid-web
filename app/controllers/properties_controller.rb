class PropertiesController < ApplicationController
  #http_basic_authenticate_with **http_auth_credentials unless Rails.env.test?
  before_action :authenticate_user!
  before_action :assign_property, only: [:show, :edit, :update, :destroy, :duplicate_leads, :user_stats]
  after_action :verify_authorized

  # GET /properties
  # GET /properties.json
  def index
    authorize Property
    @properties = Property.includes(:team).order("name ASC")
    
    # For JSON requests, only return active properties that the user has access to
    if request.format.json?
      @properties = @properties.active.joins(:users).where(users: { id: current_user.id })
    end
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
      # Get the filtered params
      filtered_params = property_params

      # Handle file uploads properly - remove empty file fields
      [:logo, :email_header_image, :email_footer_logo].each do |field|
        if filtered_params.key?(field)
          file = filtered_params[field]
          # Remove empty uploads to prevent clearing existing attachments
          unless file.is_a?(ActionDispatch::Http::UploadedFile) &&
                 file.original_filename.present? && file.size > 0
            filtered_params.delete(field)
          end
        end
      end

      if @property.update(filtered_params)
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
    #@property.destroy
    @property.active = false
    @property.save
    respond_to do |format|
      format.html { redirect_to properties_url, notice: 'Property was marked as inactive.' }
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
    redirect_to request.referer || root_path
  end

  def user_stats
    authorize @property
    service = Users::ActivityReport.new(@property)
    @stats = service.call
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def assign_property
      @property = policy_scope(Property).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def property_params
      valid_property_params = policy(Property).allowed_params
      params.require(:property).permit(*valid_property_params)
    end
end
