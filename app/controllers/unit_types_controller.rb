class UnitTypesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_property
  before_action :set_unit_type, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /unit_types
  # GET /unit_types.json
  def index
    authorize UnitType
    @unit_types = unit_type_scope.order(name: 'ASC')
  end

  # GET /unit_types/1
  # GET /unit_types/1.json
  def show
    authorize @unit_type
  end

  # GET /unit_types/new
  def new
    @unit_type = unit_type_scope.new
    @unit_type.property = @property if @property.present?
    authorize @unit_type
  end

  # GET /unit_types/1/edit
  def edit
    authorize @unit_type
  end

  # POST /unit_types
  # POST /unit_types.json
  def create
    @unit_type = unit_type_scope.new(unit_type_params)
    authorize @unit_type

    respond_to do |format|
      if @unit_type.save
        format.html { redirect_to @unit_type, notice: 'Unit type was successfully created.' }
        format.json { render :show, status: :created, location: @unit_type }
      else
        format.html { render :new }
        format.json { render json: @unit_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /unit_types/1
  # PATCH/PUT /unit_types/1.json
  def update
    authorize @unit_type
    respond_to do |format|
      if @unit_type.update(unit_type_params)
        format.html { redirect_to @unit_type, notice: 'Unit type was successfully updated.' }
        format.json { render :show, status: :ok, location: @unit_type }
      else
        format.html { render :edit }
        format.json { render json: @unit_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /unit_types/1
  # DELETE /unit_types/1.json
  def destroy
    authorize @unit_type
    @unit_type.destroy
    respond_to do |format|
      format.html { redirect_to unit_types_url, notice: 'Unit type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit_type
      @unit_type = UnitType.find(params[:id])
    end

    def set_property
      @property ||= Property.where(id: (params[:property_id] || 0)).first
    end

    def unit_type_scope
      set_property
      @property.present? ? @property.unit_types : UnitType
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_type_params
      params.require(:unit_type).permit(policy(UnitType).allowed_params)
    end
end
