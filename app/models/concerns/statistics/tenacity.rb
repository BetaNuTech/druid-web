module Statistics
  module Tenacity
    extend ActiveSupport::Concern

    included do

      def self.tenacity_grade(count)
        case count.to_i
        when 4
          'A'
        when 3
          'B'
        when 2
          'C'
        when [0,1]
          'F'
        else
          'I'
        end
      end

      def self.tenacity_grade_for(obj, interval: :month, time_start: nil)
        time_start ||= Statistic.utc_month_start - 1.month
        skope = Statistic.where(quantifiable: obj, time_start: time_start)
        statistic_record = case interval
                           when :day
                             skope = skope.daily
                           when :week
                             skope = skope.weekly
                           when :month
                             skope = skope.monthly
                           when :year
                             skope = skope.yearly
                           end.last

        self.tenacity_grade(statistic_record&.value)
      end

      # Tenacity is a function of the number of times an agent has
      # contacted leads.
      #
      # Default 'resolution' is one month
      # Default time_start is one year
      def self.generate_tenacity(resolution: nil, time_start: nil, time_end: nil)
        resolution ||= 1.month.to_i / 60
        time_start ||= Statistic.utc_month_start - 1.month
        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            contact_counts.user_id AS user_id,
            contact_counts.time_start AS time_start,
            ROUND(AVG(normalized_score)) AS avg_normal_count
          FROM
            (
              SELECT
                contact_events.user_id AS user_id,
                leads.id AS lead_id,
                COUNT(contact_events.lead_id) AS contact_count,
                ( CASE
                  WHEN COUNT(contact_events.lead_id) >= 4 THEN 4
                  ELSE COUNT(contact_events.lead_id)
                END ) AS normalized_score,
                date_trunc('month', leads.created_at) AS time_start
              FROM contact_events
              INNER JOIN leads
                ON
                  leads.id = contact_events.lead_id AND
                  ( leads.classification = 0 OR leads.classification IS NULL ) AND
                  leads.id = contact_events.lead_id AND
                  leads.state NOT IN ('resident', 'exresident') AND
                  leads.created_at BETWEEN '#{time_start}' AND '#{time_end}'
              GROUP BY
                contact_events.user_id,
                leads.id
              ORDER BY
                time_start ASC,
                user_id ASC
            ) contact_counts
          GROUP BY
            contact_counts.time_start,
            contact_counts.user_id
          ORDER BY
            contact_counts.time_start ASC,
            contact_counts.user_id ASC;
        SQL

       data = ActiveRecord::Base.connection.execute(sql).to_a

        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'tenacity',
              quantifiable_id: stat_data['user_id'],
              quantifiable_type: 'User',
              resolution: resolution,
              value: stat_data['avg_normal_count'],
              time_start: stat_data['time_start']
            )
          rescue
            # NOOP: this is a duplicate
            next
          end
        end
        true
      end # generate_tenacity

      def self.rollup_all_tenacity_intervals
        self.rollup_tenacity(interval: :year, time_start: Time.now.utc.beginning_of_year - 1.year)
      end

      def self.rollup_tenacity(interval:, time_start:)
        case interval
        when :year
          resolution = 1.month / 60
          new_resolution = 1.year / 60
          time_start = time_start.beginning_of_year
          time_end = time_start + 1.year
        else
          raise 'Invalid rollup interval'
        end

        return false if time_end > Time.now

        sql = <<~SQL
          SELECT
            quantifiable_id,
            quantifiable_type,
            ROUND(avg(value)) AS avg_tenacity
          FROM
            statistics
          WHERE
            resolution = #{resolution.to_i} AND
            time_start BETWEEN '#{time_start}' AND '#{time_end}'
          GROUP BY
            quantifiable_id,
            quantifiable_type;
        SQL

        data = ActiveRecord::Base.connection.execute(sql).to_a

        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'tenacity',
              quantifiable_id: stat_data['quantifiable_id'],
              quantifiable_type: stat_data['quantifiable_type'],
              resolution: new_resolution.to_i,
              value: stat_data['avg_tenacity'],
              time_start: time_start
            )
          rescue
            # NOOP: this is a duplicate
            next
          end
        end
        true
      end
    end
  end
end
