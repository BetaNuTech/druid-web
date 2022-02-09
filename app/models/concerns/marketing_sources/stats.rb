module MarketingSources
  module Stats
    extend ActiveSupport::Concern

    included do
      def total_spend
        marketing_expenses.sum(:fee_total)
      end

      def total_spend_ytd
        marketing_expenses.
          where(start_date: DateTime.current.beginning_of_year..DateTime.current.end_of_year).
          sum(:fee_total)
      end

      def spend_per_lead
        total_spend / [total_leads, 1].max.to_d
      end

      def spend_per_conversion
        total_spend / [total_conversions, 1].max.to_d
      end

      def total_conversions
        conversions.count
      end

      def total_conversions_ytd
        conversions.where( first_comm: DateTime.current.beginning_of_year..DateTime.current).count
      end

      def total_leads
        leads.count
      end

      def total_leads_ytd
        leads.where( first_comm: DateTime.current.beginning_of_year..DateTime.current).count
      end
    end

    class_methods do

      def total_spend(property=nil)
        skope = MarketingExpense
        skope = MarketingExpense.where(property: property) if property
        skope.sum(:fee_total)
      end

      def total_spend_ytd(property=nil)
        skope = MarketingExpense
        skope = MarketingExpense.where(property: property) if property
        skope.where(start_date: DateTime.current.beginning_of_year..DateTime.current.end_of_year).
          sum(:fee_total)
      end

      def spend_per_lead(property=nil)
        total_spend(property) / [total_leads(property), 1].max.to_d
      end

      def spend_per_conversion(property=nil)
        total_spend(property) / [total_conversions(property), 1].max.to_d
      end

      def total_conversions(property=nil)
        all_conversions(property).count
      end

      def total_conversions_ytd(property)
        all_conversions(property).where( first_comm: DateTime.current.beginning_of_year..DateTime.current).count
      end

      def total_leads(property)
        all_leads(property).count
      end

      def total_leads_ytd(property)
        all_leads(property).where( first_comm: DateTime.current.beginning_of_year..DateTime.current).count
      end
    end
  end
end
