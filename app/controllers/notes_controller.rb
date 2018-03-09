class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_note, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /notes
  # GET /notes.json
  def index
    authorize Note
    @notes = Note.all
  end

  # GET /notes/1
  # GET /notes/1.json
  def show
    authorize @note
  end

  # GET /notes/new
  def new
    @note = Note.new
    authorize @note
  end

  # GET /notes/1/edit
  def edit
    authorize @note
  end

  # POST /notes
  # POST /notes.json
  def create
    @note = Note.new(note_params)
    authorize @note
    @note.user_id = current_user.id

    respond_to do |format|
      if @note.save
        format.html { redirect_to @note, notice: 'Note was successfully created.' }
        format.json { render :show, status: :created, location: @note }
        format.js
      #else
        # THERE IS NO VALIDATION OR REASON TO FAIL
        #format.html { render :new }
        #format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notes/1
  # PATCH/PUT /notes/1.json
  def update
    authorize @note
    respond_to do |format|
      if @note.update(note_params)
        format.html { redirect_to @note, notice: 'Note was successfully updated.' }
        format.json { render :show, status: :ok, location: @note }
      #else
        # THERE IS NO VALIDATION OR REASON TO FAIL
        #format.html { render :edit }
        #format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notes/1
  # DELETE /notes/1.json
  def destroy
    authorize @note
    @note.destroy
    respond_to do |format|
      format.html { redirect_to notes_url, notice: 'Note was successfully destroyed.' }
      format.json { head :no_content }
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_note
      @note = Note.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def note_params
      params.require(:note).permit(policy(Note).allowed_params)
    end
end
