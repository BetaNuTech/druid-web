class UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /units
  # GET /units.json
  def index
    authorize Unit
    @units = unit_scope
    if @property.present?
      @units = @units.where(property_id: @property.id).
        joins("right outer join unit_types on unit_types.id = units.unit_type_id").
        order("unit_types.name ASC, units.unit ASC")
    else
      @units = Unit.where("1=0")
    end
    @show_all = params[:all] == 'true'

    unless @show_all
      @units = @units.select{|u| u.available?}
    end

  end

  # GET /units/1
  # GET /units/1.json
  def show
    authorize @unit
  end

  # GET /units/new
  def new
    @unit = unit_scope.new
    @unit.property = @property if @property.present?
    authorize @unit
  end

  # GET /units/1/edit
  def edit
    authorize @unit
  end

  # POST /units
  # POST /units.json
  def create
    @unit = unit_scope.new(unit_params)

    authorize @unit
    respond_to do |format|
      if @unit.save
        format.html { redirect_to @unit, notice: 'Unit was successfully created.' }
        format.json { render :show, status: :created, location: @unit }
      else
        format.html { render :new }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /units/1
  # PATCH/PUT /units/1.json
  def update
    authorize @unit
    respond_to do |format|
      if @unit.update(unit_params)
        format.html { redirect_to @unit, notice: 'Unit was successfully updated.' }
        format.json { render :show, status: :ok, location: @unit }
      else
        format.html { render :edit }
        format.json { render json: @unit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /units/1
  # DELETE /units/1.json
  def destroy
    authorize @unit
    @unit.destroy
    respond_to do |format|
      format.html { redirect_to units_url, notice: 'Unit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_unit
      @unit = unit_scope.find(params[:id])
    end

    def unit_scope
      policy_scope(Unit)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def unit_params
      params.require(:unit).permit(policy(Unit).allowed_params)
    end
end
