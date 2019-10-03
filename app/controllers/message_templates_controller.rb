class MessageTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message_template, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /message_templates
  # GET /message_templates.json
  def index
    authorize MessageTemplate
    @message_templates = policy_scope(MessageTemplate).order(:name)
  end

  # GET /message_templates/1
  # GET /message_templates/1.json
  def show
    authorize @message_template
  end

  # GET /message_templates/new
  def new
    @message_template = MessageTemplate.new(user: current_user)
    authorize @message_template
  end

  # GET /message_templates/1/edit
  def edit
    authorize @message_template
  end

  # POST /message_templates
  # POST /message_templates.json
  def create
    @message_template = MessageTemplate.new(message_template_params)
    authorize @message_template

    respond_to do |format|
      if @message_template.save
        format.html { redirect_to @message_template, notice: 'Message template was successfully created.' }
        format.json { render :show, status: :created, location: @message_template }
      else
        format.html { render :new }
        format.json { render json: @message_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /message_templates/1
  # PATCH/PUT /message_templates/1.json
  def update
    authorize @message_template
    respond_to do |format|
      if @message_template.update(message_template_params)
        format.html { redirect_to @message_template, notice: 'Message template was successfully updated.' }
        format.json { render :show, status: :ok, location: @message_template }
      else
        format.html { render :edit }
        format.json { render json: @message_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /message_templates/1
  # DELETE /message_templates/1.json
  def destroy
    authorize @message_template
    @message_template.destroy
    respond_to do |format|
      format.html { redirect_to message_templates_url, notice: 'Message template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_message_template
      @message_template = policy_scope(MessageTemplate).find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def message_template_params
      params.fetch(:message_template, {})
      params.require(:message_template).permit(policy(MessageTemplate).allowed_params)
    end
end
