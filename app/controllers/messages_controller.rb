class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:show, :edit, :update, :destroy]
  before_action :set_message_type, only: [:show, :new, :edit, :create ]
  before_action :set_message_template, only: [:show, :new, :edit, :create ]
  before_action :set_messageable, only: [:index, :new, :show, :edit, :update, :create]
  after_action :verify_authorized

  # GET /messages
  # GET /messages.json
  def index
    authorize Message
    @messages = record_scope.includes([:messageable, :message_type, :deliveries])
    @messages = @messages.page(params[:page])
  end

  # GET /messages/1
  # GET /messages/1.json
  def show
    authorize @message
    Message.mark_read!(@message, current_user) if !@message.read? && policy(@message).mark_read?
  end

  def body_preview
    set_message
    authorize @message
    render plain: @message.body_for_html_preview, content_type: 'text/html'
  end

  # GET /messages/new
  def new
    if (reply_to_id = params[:reply_to]).present?
      origin = Message.find(reply_to_id)
      @message = origin.new_reply(user: current_user)
    else
      @message = Message.new(
        user: current_user,
        message_type: @message_type,
        message_type_id: @message_type.try(:id),
        message_template_id: @message_template.try(:id),
        messageable: @messageable
      )
    end
    authorize @message
    @message.load_template
  end

  # GET /messages/1/edit
  def edit
    authorize @message
  end

  # POST /messages
  # POST /messages.json
  def create
    authorize Message.new
    @message = Message.new_message(
      from: current_user,
      to: @messageable,
      message_type: @message_type,
      message_template: @message_template,
      subject: params[:message][:subject],
      body: params[:message][:body]
    )

    respond_to do |format|
      if @message.save
        format.html do
          if params[:send_now].present?
            deliver_message
          else
            redirect_to @message, notice: 'Message was successfully created.'
          end
        end
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /messages/1
  # PATCH/PUT /messages/1.json
  def update
    respond_to do |format|
      authorize @message
      if @message.update(message_params)
        format.html do
          if params[:send_now].present?
            deliver_message
          else
            redirect_to @message, notice: 'Message was successfully updated.'
          end
        end
        format.json { render :show, status: :ok, location: @message }
      else
        format.html { render :edit }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /messages/1
  # DELETE /messages/1.json
  def destroy
    authorize @message
    messageable = @message.messageable
    @message.destroy
    respond_to do |format|
      format.html { redirect_to messageable, notice: 'Draft Message was deleted' }
      format.json { head :no_content }
    end
  end

  def deliver
    set_message
    authorize @message
    deliver_message
  end

  def mark_read
    set_message
    authorize @message
    Message.mark_read!(@message, current_user)
    redirect_to messages_path, notice: 'Marked message as read'
  end


  private

    def deliver_message
      @message.deliver!
      Message.mark_read!(@message, current_user)
      redirect_to @message.messageable, notice: 'Message Sent'
    end

    def record_scope
      return @messageable.present? ?
        policy_scope(@messageable.messages) :
        policy_scope(Message)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_message
      @message = record_scope.find(params[:id] || params[:message_id])
    end

    def set_messageable
      @messageable = Message.identify_messageable_from_params(params) || @message.try(:messageable)
    end

    def set_message_type
      if (message_type_id = (( params[:message] || {} ).fetch(:message_type_id, params[:message_type_id]))).present?
        @message_type = MessageType.find(message_type_id)
      else
        @message_type = @message.try(:message_type)
      end
    end

    def set_message_template
      params.permit(:message_template_id)
      if (message_template_id = (( params[:message] || {} ).fetch(:message_template_id, params[:message_template_id]))).present?
        @message_template = MessageTemplate.find(message_template_id)
      else
        @message_template = @message.try(:message_template)
      end
    end

    def message_params
      allowed_params = policy(@message||Message).allowed_params
      params.require(:message).permit(*allowed_params)
    end
end
