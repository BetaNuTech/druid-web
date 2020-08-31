class MarketingExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_marketing_source
  before_action :set_marketing_expense, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  def index
    authorize MarketingExpense
    raise ActiveRecord::RecordNotFound
  end

  def new
    @marketing_expense = MarketingExpense.new(
      property: @marketing_source.property,
      marketing_source: @marketing_source,
      fee_type: @marketing_source.fee_type
    )
    authorize @marketing_expense
  end

  def create
    @marketing_expense = MarketingExpense.new(marketing_expense_params)
    @marketing_expense.marketing_source_id = @marketing_source.id
    @marketing_expense.property_id = @marketing_source.property_id
    authorize @marketing_expense

    respond_to do |format|
      if @marketing_expense.save
        format.html { redirect_to marketing_sources_path(property_id: @marketing_source.property_id) + "##{@marketing_source.id}" , notice: 'Marketing Expense was created' }
      else
        format.html { render :new }
      end
    end
  end

  def show
    authorize @marketing_expense
  end

  def edit
    authorize @marketing_expense
  end

  def update
    authorize @marketing_expense
    respond_to do |format|
      if @marketing_expense.update(marketing_expense_params)
        format.html { redirect_to marketing_sources_path(property_id: @marketing_source.property_id) + "##{@marketing_source.id}", notice: 'Marketing Expense was updated' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    authorize @marketing_expense
    @marketing_expense.destroy
    respond_to do |format|
      format.html { redirect_to marketing_sources_path(property_id: @marketing_expense.property_id) }
    end
  end

  private

  def marketing_source_scope(skope=MarketingSource)
    policy_scope(skope)
  end

  def set_marketing_source
    @marketing_source ||= marketing_source_scope.find(params[:marketing_source_id])
  end

  def marketing_expense_scope(skope=nil)
    policy_scope( skope || @marketing_source.marketing_expenses )
  end

  def set_marketing_expense
    @marketing_expense ||= marketing_expense_scope.find(params[:id])
  end

  def marketing_expense_params
    allowed_params = policy(@marketing_expense || MarketingExpense).allowed_params
    params.require(:marketing_expense).permit(*allowed_params)
  end
end
