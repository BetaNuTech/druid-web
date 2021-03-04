require 'rails_helper'

RSpec.describe MarketingExpense, type: :model do

  describe 'Initialization' do
    it 'should be valid' do
      expect(build(:marketing_expense)).to be_valid
    end
  end

  describe 'validation' do
    it 'should have a start_date < end_date' do
      expense = build(:marketing_expense)
      expense.end_date = nil
      assert(expense.valid?)
      expense.end_date = expense.start_date + 1.day
      assert(expense.valid?)
      expense.end_date = expense.start_date - 1.day
      refute(expense.valid?)
    end
  end

  let(:reference_marketing_expense) {
    build(:marketing_expense,
          property: marketing_source.property,
          marketing_source: marketing_source,
          fee_type: marketing_source.fee_type,
          start_date: 2.weeks.ago,
          end_date: 1.month.from_now
         )
  }
  let(:old_similar_marketing_expense) {
    create(:marketing_expense,
           property: marketing_source.property,
           marketing_source: marketing_source,
           fee_type: marketing_source.fee_type,
           start_date: 3.months.ago,
           end_date: 2.months.ago
          )
  }
  let(:old_alternate_marketing_expense) {
    create(:marketing_expense,
           property: marketing_source.property,
           marketing_source: marketing_source,
           fee_type: MarketingSource::LEAD_FEE,
           start_date: 3.months.ago,
           end_date: 2.months.ago
          )
  }
  let(:recent_similar_marketing_expense) {
    create(:marketing_expense,
           property: marketing_source.property,
           marketing_source: marketing_source,
           fee_type: marketing_source.fee_type,
           start_date: 3.weeks.ago,
           end_date: 1.week.ago
          )
  }
  let(:recent_alternate_marketing_expense) {
    create(:marketing_expense,
           property: marketing_source.property,
           marketing_source: marketing_source,
           fee_type: MarketingSource::LEAD_FEE,
           start_date: 3.weeks.ago,
           end_date: 1.week.ago
          )
  }
  let(:marketing_source) {
    create(:marketing_source,
           fee_type: MarketingSource::MONTHLY_FEE,
           start_date: 4.months.ago,
           end_date: 6.months.from_now
          )
  }

  before(:each) do
    old_similar_marketing_expense
    old_alternate_marketing_expense
  end

  describe 'auto-generation' do
    describe 'when the current date is within the MarketingSource activity period' do
      describe 'when there are no matching expenses within the period' do
        describe 'when the fee type is periodic' do
          describe 'when the MarketingSource activity period is fully within the implied fee type period' do
            it 'creates a marketing expense of the same fee type as the MarketingSource with a period matching the fee type period' do
              count = MarketingExpense.count
              assert(marketing_source.periodically_billable?)
              new_expense = marketing_source.create_pending_expense
              assert(new_expense.valid?)
              assert(new_expense.persisted?)
              expect(MarketingExpense.count).to eq(count + 1)
              expect(new_expense.fee_type).to eq(marketing_source.fee_type)
              expect(new_expense.start_date).to eq(Date.today.beginning_of_month)
              expect(new_expense.end_date).to eq(Date.today.end_of_month)
            end
          end
          describe 'when the MarketingSource activity period is partially within the implied fee type period' do
            it 'creates a marketing expense of the same fee type as the MarketingSource with a period within the MarketingSource activity period' 
            #it 'creates a marketing expense of the same fee type as the MarketingSource with a period within the MarketingSource activity period' do
              #marketing_source.update!(
                #start_date: 3.weeks.ago,
                #end_date: DateTime.now.end_of_month + 2.days
              #)
              #assert(marketing_source.create_pending_expense)
              #new_expense = MarketingExpense.order(created_at: :desc).first
              #assert(new_expense.persisted?)
              #expect(new_expense.start_date.to_s).to eq(marketing_source.start_date.to_s)
              #expect(new_expense.end_date.to_s).to eq(Date.today.end_of_month.to_s)

              #MarketingExpense.destroy_all
              #marketing_source.update!(
                #start_date: 3.weeks.ago,
                #end_date: Date.today.end_of_month - 2.days
              #)
              #assert(marketing_source.create_pending_expense)
              #new_expense = MarketingExpense.order(created_at: :desc).first
              #assert(new_expense.persisted?)
              #expect(new_expense.start_date).to eq(marketing_source.start_date)
              #expect(new_expense.end_date).to eq(marketing_source.end_date)
            #end
          end
        end
        describe 'when the fee type is not periodic' do
          it 'returns an unsaved MarketingExpense with errors'
        end
      end
      describe 'when there are matching expenses within the period' do
        it 'returns an unsaved MarketingExpense with errors'
      end
    end
    describe 'when the current date is outside the MarketingSource activity period'
  end

end
