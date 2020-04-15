class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :destroy]
  after_action :verify_authorized

  # GET /users
  # GET /users.json
  def index
    authorize User
    @users = User.includes(:profile).order('user_profiles.last_name ASC, user_profiles.first_name ASC')
  end

  # GET /users/1
  # GET /users/1.json
  def show
    authorize @user
  end

  # GET /users/new
  def new
    @creator = Users::Creator.new(params: {user: {id: nil}}, creator: current_user)
    @user = @creator.user
    authorize @user
  end

  # GET /users/1/edit
  def edit
    @creator = Users::Creator.new(params: params, creator: current_user)
    @user = @creator.user
    authorize @user
  end

  # POST /users
  # POST /users.json
  def create
    authorize User
    @creator = Users::Creator.new(params: params, creator: current_user)
    @creator.save
    @user = @creator.user
    respond_to do |format|
      if @creator.valid?
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    @creator = Users::Creator.new(params: params, creator: current_user)
    authorize @creator.user
    @creator.save
    @user = @creator.user
    respond_to do |format|
      if @creator.valid?
        format.html { redirect_to edit_user_path(@user), notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    authorize @user
    @user.deactivate!
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was deactivated.' }
      format.json { head :no_content }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

end
