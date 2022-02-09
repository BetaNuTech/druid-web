module MarketingSources
  class Report
    include ActiveModel::Model
    COLUMNS = %w[source total_cost leads_count prospect_count showing_count leases_count cost_per_prospect cost_per_showing cost_per_lease].freeze
    REPORT_TYPES = %w[adspend expense_export source_export phone_export].freeze
    DEFAULT_REPORT_TYPE = 'adspend'

    attr_accessor :start_date, :end_date, :property_ids, :report_type

    def initialize(params={})
      if params.respond_to?(:to_unsafe_h)
        options = params&.to_unsafe_h || params || {}
      else
        options = params || {}
      end
      @start_date, @end_date = process_dates(options)
      @property_ids = process_property_ids(options)
      @report_type = process_report_type(options)
    end

    def call
      case @report_type
        when 'adspend'
          spend_report
        else
          raise 'Invalid Report Type'
       end
    end

    def csv
      case @report_type
        when 'adspend'
          spend_report_csv
        when 'expense_export'
          expense_export
        when 'source_export'
          source_export
        when 'phone_export'
          phone_export_csv
        else
          raise 'Invalid Report Type'
      end
    end

    def csv_filename
      prefix = case @report_type
        when 'adspend'
          'ad_spend'
        when 'expense_export'
          'marketing_expense'
        when 'source_export'
          'marketing_source'
        when 'phone_export'
          'phone_tracking'
        else
          raise 'Invalid Report Type'
      end
      DateTime.current.strftime("#{prefix}_report-%Y-%m-%d-%H%M.csv")
    end

    private

    def phone_export_csv
      CSV.generate do |csv|
        csv << [ 'Source', 'Property', 'Number' ]
        phone_export.each do |record|
          csv << [
            record['source'],
            record['property'],
            record['number']
          ]
        end
      end
    end

    def phone_export
      sql = <<~SQL
        SELECT
          marketing_sources.name AS source,
            properties.name AS property,
            marketing_sources.tracking_number AS number
        FROM marketing_sources
        INNER JOIN properties
          ON marketing_sources.property_id = properties.id
        WHERE
          marketing_sources.tracking_number IS NOT NULL
          AND marketing_sources.tracking_number != ''
        ORDER BY
          marketing_sources.name ASC, properties.name ASC;
      SQL

      ActiveRecord::Base.connection.execute(sql).to_a
    end


    def spend_report_csv
      CSV.generate do |csv|
        csv << [
          'Source',
          'Leads',
          'Prospects',
          'Showings',
          'Leases',
          'Total Cost',
          'Cost/Lead',
          'Cost/Prospect',
          'Cost/Lease'
        ]
        spend_report.each do |row|
          csv << [
            row['source'],
            row['lead_count'],
            row['prospect_count'],
            row['showing_count'],
            row['lease_count'],
            row['total_cost'],
            row['cost_per_lead'],
            row['cost_per_prospect'],
            row['cost_per_lease']
          ]
        end
      end
    end

    def expense_export
      skope = MarketingExpense.includes(:property, :marketing_source)
      skope = skope.where(property_id: @property_ids) if @property_ids.present?
      skope = skope.where(start_date: @start_date..@end_date)
      CSV.generate do |csv|
        csv << %w[Property StartDate EndDate Source FeeType Invoice Description Quantity Total]
        skope.all.each do |expense|
          csv << [
            expense.property.name,
            expense.start_date,
            expense.end_date,
            expense.marketing_source.name,
            expense.fee_type,
            expense.invoice,
            expense.description,
            expense.quantity,
            expense.fee_total
          ]
        end
      end
    end

    def source_export
      skope = MarketingSource.includes(:property)
      skope = skope.where(property_id: @property_ids) if @property_ids.present?
      CSV.generate do |csv|
        csv << %w[Property Name Description FeeType FeeRate TrackingEmail TrackingNumber DestinationNumber StartDate EndDate]
        skope.all.each do |source|
          csv << [
            source.property.name,
            source.name,
            source.description,
            source.fee_type,
            source.fee_rate,
            source.tracking_email,
            source.tracking_number,
            source.destination_number,
            source.start_date,
            source.end_date
          ]
        end
      end
    end


    def process_dates(options)
      default_start = Date.current.beginning_of_year
      default_end = Date.current
      start_date = Date.parse(options[:start_date]) rescue default_start
      end_date = Date.parse(options[:end_date]) rescue default_end
      end_date = start_date if start_date > end_date
      [start_date, end_date]
    end

    def process_property_ids(options)
      property_ids = options.fetch(:property_ids,[]).compact
      property_ids.reject!{|p| p.empty? }
      property_ids.empty? ? nil : property_ids
    end

    def spend_report
      if @property_ids.present?
        property_sql = "property_id IN (#{@property_ids.map{|p| "'#{p}'"}.join(',')})"
      else
        property_sql = nil
      end

      sql= <<~SQL
        SELECT
          marketing_costs.source_name AS source,
          COALESCE(marketing_costs.total_cost, 0) AS total_cost,
          COALESCE(lead_counts.lead_count, 0) AS lead_count,
          COALESCE(prospect_counts.prospect_count, 0) AS prospect_count,
          COALESCE(showing_counts.showing_count, 0) AS showing_count,
          COALESCE(lease_counts.lease_count, 0) AS lease_count,
          ROUND(COALESCE((total_cost/lead_count),0),2) AS cost_per_lead,
          ROUND(COALESCE((total_cost/prospect_count),0),2) AS cost_per_prospect,
          ROUND(COALESCE((total_cost/showing_count),0),2) AS cost_per_showing,
          ROUND(COALESCE((total_cost/lease_count),0),2) AS cost_per_lease
        FROM (
          SELECT
            marketing_sources.name AS source_name,
            SUM(COALESCE(marketing_expenses.fee_total,0)) AS total_cost
          FROM
            marketing_sources
          LEFT JOIN
            marketing_expenses ON
              marketing_expenses.marketing_source_id = marketing_sources.id
              AND marketing_expenses.start_date BETWEEN '#{@start_date}' AND '#{@end_date}'
              #{"AND marketing_expenses.#{property_sql}" if property_sql}
          GROUP BY
            marketing_sources.name
          ) AS marketing_costs
        LEFT JOIN (
          SELECT
            leads.referral AS referral,
            COUNT(leads.id) AS lead_count
          FROM
            leads
          WHERE
            created_at BETWEEN '#{@start_date}' AND '#{@end_date}'
            #{"AND leads.#{property_sql}" if property_sql}
          GROUP BY
            leads.referral
        ) AS lead_counts ON
          lead_counts.referral = marketing_costs.source_name
        LEFT JOIN (
          SELECT
            leads.referral AS referral,
            COUNT(lead_transitions.id) AS prospect_count
          FROM
            leads
          INNER JOIN
            lead_transitions ON
              lead_transitions.lead_id = leads.id
              AND lead_transitions.last_state = 'open' AND lead_transitions.current_state = 'prospect'
          WHERE
            leads.created_at BETWEEN '#{@start_date}' AND '#{@end_date}'
            #{"AND leads.#{property_sql}" if property_sql}
          GROUP BY
            leads.referral
        ) AS prospect_counts ON
          prospect_counts.referral = marketing_costs.source_name
        LEFT JOIN (
          SELECT
            leads.referral AS referral,
            COUNT(scheduled_actions.id) AS showing_count
          FROM leads
          INNER JOIN
            scheduled_actions ON
              scheduled_actions.target_type = 'Lead'
              AND scheduled_actions.target_id = leads.id
              AND scheduled_actions.article_type = 'Unit'
              AND scheduled_actions.state = 'completed'
          WHERE
            leads.created_at BETWEEN '#{@start_date}' AND '#{@end_date}'
            #{"AND leads.#{property_sql}" if property_sql}
          GROUP BY
            leads.referral
        ) AS showing_counts ON
          showing_counts.referral = marketing_costs.source_name
        LEFT JOIN (
          SELECT
            leads.referral AS referral,
            COUNT(lead_transitions.id) AS lease_count
          FROM
            leads
          INNER JOIN
            lead_transitions ON
              lead_transitions.lead_id = leads.id
              AND lead_transitions.current_state = 'resident'
          WHERE
            leads.created_at BETWEEN '#{@start_date}' AND '#{@end_date}'
            #{"AND leads.#{property_sql}" if property_sql}
          GROUP BY
            leads.referral
        ) AS lease_counts ON
          lease_counts.referral = marketing_costs.source_name
        ORDER BY
          marketing_costs.source_name ASC
      SQL

      ActiveRecord::Base.connection.execute(sql).to_a
    end

    def process_report_type(options)
      @report_type = REPORT_TYPES.include?(options[:report_type].to_s) ? options[:report_type].to_s : DEFAULT_REPORT_TYPE
    end

  end
end
