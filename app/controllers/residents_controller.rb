class ResidentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resident, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /residents
  # GET /residents.json
  def index
    authorize Resident
    @residents = resident_scope.includes(:unit).order("units.unit ASC, residents.last_name ASC, residents.first_name ASC")
  end

  # GET /residents/1
  # GET /residents/1.json
  def show
    authorize @resident
  end

  # GET /residents/new
  def new
    @resident = resident_scope.new
    authorize @resident
  end

  # GET /residents/1/edit
  def edit
    authorize @resident
  end

  # POST /residents
  # POST /residents.json
  def create
    @resident = resident_scope.new
    authorize @resident
    @resident.attributes = resident_params

    respond_to do |format|
      if @resident.save
        format.html { redirect_to @resident, notice: 'Resident was successfully created.' }
        format.json { render :show, status: :created, location: @resident }
      else
        format.html { render :new }
        format.json { render json: @resident.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /residents/1
  # PATCH/PUT /residents/1.json
  def update
    authorize @resident
    respond_to do |format|
      if @resident.update(resident_params)
        format.html { redirect_to @resident, notice: 'Resident was successfully updated.' }
        format.json { render :show, status: :ok, location: @resident }
      else
        format.html { render :edit }
        format.json { render json: @resident.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /residents/1
  # DELETE /residents/1.json
  def destroy
    authorize @resident
    @resident.destroy
    respond_to do |format|
      format.html { redirect_to residents_url, notice: 'Resident was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resident
      @resident = resident_scope.find(params[:id])
    end

    def resident_scope
      default_skope = policy_scope(Resident)
      if params[:override_scope]
        return default_skope
      else
        @property.present? ? @property.residents : default_skope
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resident_params
      params.require(:resident).permit(policy(Resident).allowed_params)
    end
end
