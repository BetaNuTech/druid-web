class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, only: [:show, :edit, :update, :destroy, :add_member]
  after_action :verify_authorized

  # GET /teams
  # GET /teams.json
  def index
    authorize Team
    @teams = Team.all
  end

  # GET /teams/1
  # GET /teams/1.json
  def show
    authorize @team
  end

  # GET /teams/new
  def new
    authorize Team
    @team = Team.new
  end

  # GET /teams/1/edit
  def edit
    authorize @team
  end

  # POST /teams
  # POST /teams.json
  def create
    @team = Team.new(team_params)
    authorize @team

    respond_to do |format|
      if @team.save
        format.html { redirect_to @team, notice: 'Team was successfully created.' }
        format.json { render :show, status: :created, location: @team }
      else
        format.html { render :new }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /teams/1
  # PATCH/PUT /teams/1.json
  def update
    authorize @team
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to @team, notice: 'Team was successfully updated.' }
        format.json { render :show, status: :ok, location: @team }
      else
        format.html { render :edit }
        format.json { render json: @team.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /teams/1
  # DELETE /teams/1.json
  def destroy
    authorize @team
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url, notice: 'Team was removed.' }
      format.json { head :no_content }
    end
  end

  def add_member
    authorize @team
    @membership = @team.memberships.build
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_team
      @team = Team.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def team_params
      allowed_params = policy(@team || Team).allowed_params
      params.require(:team).permit(*allowed_params)
    end
end
