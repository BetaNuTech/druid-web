# == Schema Information
#
# Table name: marketing_expenses
#
#  id                  :uuid             not null, primary key
#  property_id         :uuid             not null
#  marketing_source_id :uuid             not null
#  invoice             :string
#  description         :text
#  fee_total           :decimal(, )      not null
#  fee_type            :integer          default("free"), not null
#  quantity            :integer          default(1), not null
#  start_date          :date             not null
#  end_date            :date
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

RSpec.describe MarketingExpense, type: :model do
  describe 'initialization' do
    it 'should create a MarketingExpense' do
      expense = create(:marketing_expense)
      assert(expense.valid?)
    end
  end

  describe 'validations' do
    let(:marketing_expense) { build(:marketing_expense) }

    it 'should require a positive integer quantity' do
      assert(marketing_expense.valid?)
      marketing_expense.quantity = nil
      refute(marketing_expense.valid?)
      marketing_expense.quantity = -1
      refute(marketing_expense.valid?)
      marketing_expense.quantity = 1
      assert(marketing_expense.valid?)
      marketing_expense.quantity = 0.1
      refute(marketing_expense.valid?)
    end

    it 'should have a non-negative fee_total' do
      marketing_expense.fee_total = 0.1
      assert(marketing_expense.valid?)
      marketing_expense.fee_total = 0.0
      assert(marketing_expense.valid?)
      marketing_expense.fee_total = -0.1
      refute(marketing_expense.valid?)
    end

    it 'should have a start_date' do
      assert(marketing_expense.valid?)
      marketing_expense.start_date = nil
      refute(marketing_expense.valid?)
    end
  end
end
