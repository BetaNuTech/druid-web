class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /users
  # GET /users.json
  def index
    authorize User
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
    authorize @user
  end

  # GET /users/new
  def new
    @user = User.new
    authorize @user
  end

  # GET /users/1/edit
  def edit
    authorize @user
  end

  # POST /users
  # POST /users.json
  def create
    authorize User
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
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
    authorize @user
    respond_to do |format|
      if @user.update(user_params)
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
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    # Do not require password confirmation if password is not provided
    if params[:user].present?
      if params[:user][:password].blank?
        params[:user].delete(:password)
        params[:user].delete(:password_confirmation)
      end
    end

    # Determine Allowed User params by Policy
    valid_user_params = policy(User).allowed_params

    if @user.present?
      # Prevent privilege escalation of Role
      unless policy(@user).may_change_role?((params[:user][:role_id] rescue nil))
        valid_user_params = valid_user_params - [:role_id]
        logger.warn("WARNING: UsersController Prevented Role promotion of User[#{@user.try(:id) || 'NEW'}] by User[#{current_user.id}]")
      end

      # Prevent privilege escalation of TeamRole
      unless policy(@user).may_change_teamrole?((params[:user][:teamrole_id] rescue nil))
        valid_user_params = valid_user_params - [:teamrole_id]
        logger.warn("WARNING: UsersController Prevented TeamRole promotion of User[#{@user.try(:id) || 'NEW'}] by User[#{current_user.id}]")
      end
    end

    allow_params = params.require(:user).permit(*valid_user_params)
    logger.debug("DEBUG: UserController allowing params for #{current_user.email} to edit #{@user.try(:email)} #{allow_params.inspect}")
    allow_params
  end

end
