class ResidentDetailsController < ApplicationController
  before_action :set_resident_detail, only: [:show, :edit, :update, :destroy]

  # GET /resident_details
  # GET /resident_details.json
  def index
    @resident_details = ResidentDetail.all
  end

  # GET /resident_details/1
  # GET /resident_details/1.json
  def show
  end

  # GET /resident_details/new
  def new
    @resident_detail = ResidentDetail.new
  end

  # GET /resident_details/1/edit
  def edit
  end

  # POST /resident_details
  # POST /resident_details.json
  def create
    @resident_detail = ResidentDetail.new(resident_detail_params)

    respond_to do |format|
      if @resident_detail.save
        format.html { redirect_to @resident_detail, notice: 'Resident detail was successfully created.' }
        format.json { render :show, status: :created, location: @resident_detail }
      else
        format.html { render :new }
        format.json { render json: @resident_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /resident_details/1
  # PATCH/PUT /resident_details/1.json
  def update
    respond_to do |format|
      if @resident_detail.update(resident_detail_params)
        format.html { redirect_to @resident_detail, notice: 'Resident detail was successfully updated.' }
        format.json { render :show, status: :ok, location: @resident_detail }
      else
        format.html { render :edit }
        format.json { render json: @resident_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /resident_details/1
  # DELETE /resident_details/1.json
  def destroy
    @resident_detail.destroy
    respond_to do |format|
      format.html { redirect_to resident_details_url, notice: 'Resident detail was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_resident_detail
      @resident_detail = ResidentDetail.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def resident_detail_params
      params.require(:resident_detail).permit(:resident_id, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :email, :ssn, :id_number, :id_state)
    end
end
