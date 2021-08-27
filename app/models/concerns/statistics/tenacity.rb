module Statistics
  module Tenacity
    extend ActiveSupport::Concern

    included do

      def self.tenacity_grade(value)
        case value.to_i
        when 3,4
          '10'
        when 2
          '5'
        when 0,1
          '1'
        else
          'NA'
        end
      end

      def self.tenacity_grade_for(obj, interval: :month, time_start: nil)
        time_start ||= Statistic.utc_month_start - 1.month
        skope = Statistic.where(quantifiable: obj, time_start: time_start).tenacity
        statistic_record = case interval
                           when :day
                             skope.daily
                           when :week
                             skope.weekly
                           when :month
                             skope.monthly
                           when :year
                             skope.yearly
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
                  WHEN COUNT(contact_events.lead_id) >= 3 THEN 3
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

      # Tenacity is a function of the number of times an agent has
      # contacted leads.
      #
      # Default 'resolution' is one month
      # Default time_start is one year
      def self.generate_property_tenacity(property:, resolution: nil, time_start: nil, time_end: nil)
        user_ids = property.property_users.pluck(:user_id)
        user_ids_sql = "(" + user_ids.map {|uid| "'#{uid}'"}.join(', ') + ")"
        resolution ||= 1.month.to_i / 60
        time_start ||= Statistic.utc_month_start - 1.month
        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            property_users.property_id AS property_id,
            contact_counts.time_start AS time_start,
            ROUND(AVG(normalized_score)) AS avg_normal_count
          FROM
            (
              SELECT
                contact_events.user_id AS user_id,
                leads.id AS lead_id,
                COUNT(contact_events.lead_id) AS contact_count,
                ( CASE
                  WHEN COUNT(contact_events.lead_id) >= 3 THEN 3
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
          INNER JOIN property_users
            ON property_users.user_id = contact_counts.user_id
          GROUP BY
            contact_counts.time_start,
            property_users.property_id
          ORDER BY
            contact_counts.time_start ASC,
            property_users.property_id ASC
        SQL

       data = ActiveRecord::Base.connection.execute(sql).to_a

        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'tenacity',
              quantifiable_id: stat_data['property_id'],
              quantifiable_type: 'Property',
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
      end # generate_property_tenacity

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


      def self.backfill_tenacity(time_start:, time_end: )
        resolution = 1.week / 60
        cursor = time_start.beginning_of_hour
        while cursor <= time_end
          cursor_end = cursor + resolution.minutes
          self.generate_tenacity(resolution: resolution, time_start: cursor, time_end: cursor_end)
          Property.active.each do |property|
            self.generate_property_tenacity(property: property, resolution: resolution, time_start: cursor, time_end: cursor_end)
          end
          cursor += resolution.minutes
        end

        cursor = time_start.beginning_of_year
        while cursor <= time_end
          self.rollup_tenacity(interval: :year, time_start: cursor.beginning_of_year)
          cursor += 1.month
        end
      end

      def self.interval_from_date_range(label)
        {
          'today': :day,
          'last_week': :week,
          'last_month': :month,
          'last_quarter': :month,
          'last_year': :year,
          'all_time': :year,
          'week': :week,
          '2weeks': :week,
          'month': :month,
          '3months': :month,
          'year': :year
        }.fetch(label.to_s, :month)
      end

      def self.statistic_time_start(interval)
        last_day = Statistic.utc_day_start - 1.days
        last_week = Statistic.utc_week_start - 1.week
        last_month = Statistic.utc_month_start - 1.month
        last_quarter = Statistic.utc_quarter_start - 3.months
        last_year = Statistic.utc_year_start - 1.year
        {
          'today': last_day,
          'last_week': last_week,
          'last_month': last_month,
          'last_quarter': last_quarter,
          'last_year': last_year,
          'all_time': last_year,
          'week': last_week,
          '2weeks': last_week,
          'month': last_month,
          '3months': last_quarter,
          'year':last_year 
        }.fetch(interval.to_s, last_month)
      end
    end
  end
end
