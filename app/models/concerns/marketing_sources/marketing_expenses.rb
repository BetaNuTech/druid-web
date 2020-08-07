module MarketingSources
  module MarketingExpenses
    extend ActiveSupport::Concern

    included do
      has_many :marketing_expenses, dependent: :destroy

      def create_pending_expense
        expense = new_expected_expense
        expense.errors[:base] << 'MarketingSource is not periodically billable' if !periodically_billable?
        expense.errors[:base] << 'MarketingSource already has the expected expense this period' if expected_expenses_this_billing_period.any?
        expense.marketing_source_id = nil if expense.errors.any?
        expense.save
        expense
      end

      def periodically_billable?
        current_billing_period.present?
      end

      def new_expected_expense
        billing_period = current_billing_period
        marketing_expense = MarketingExpense.new(
          property: property,
          marketing_source: self,
          invoice: nil,
          description: "#{fee_type} fee",
          fee_total: fee_rate,
          fee_type: fee_type,
          quantity: 1,
          start_date: billing_period ? billing_period.first : nil,
          end_date: billing_period ? billing_period.last : nil
        )
      end

      def expected_expenses_this_billing_period(reference_date = DateTime.now)
        marketing_expenses.where(start_date: current_billing_period(reference_date), fee_type: fee_type)
      end

      # Returns a DateTime range depending on the fee_type
      def current_billing_period(reference_date = DateTime.now)
        case fee_type
        when MarketingSource::MONTHLY_FEE
          proposed_start = reference_date.beginning_of_month
          proposed_end = reference_date.end_of_month
        when MarketingSource::QUARTERLY_FEE
          proposed_start = reference_date.beginning_of_quarter
          proposed_end = reference_date.end_of_quarter
        when MarketingSource::YEARLY_FEE
          proposed_start = reference_date.beginning_of_year
          proposed_end = reference_date.end_of_year
        else
          return nil
        end

        return nil if proposed_end < start_date
        return nil if end_date.present? && proposed_start >= end_date

        proposed_start = [proposed_start, start_date].compact.max
        proposed_end = [proposed_end, end_date].compact.min

        proposed_start..proposed_end
      end
    end
  end
end
