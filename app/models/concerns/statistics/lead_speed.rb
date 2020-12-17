module Statistics
  module LeadSpeed
    extend ActiveSupport::Concern

    included do

      def self.lead_speed_grade(minutes)
        case minutes
        when (0..29)
          'A'
        when (30..120)
          'B'
        when nil
          'I'
        else
          'C'
        end
      end

      def self.lead_speed_grade_for(obj, interval: :week, time_start:)
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

        self.lead_speed_grade(statistic_record&.value)
      end

      # Generate LeadSpeed statistics
      #
      # resolution: Integer (minutes)
      # time_start: Time
      # time_end: Time (default: Now)
      def self.generate_leadspeed(resolution: 60, time_start:, time_end: nil)
        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            user_id,
            CEIL(avg(lead_time)) AS avg_leadtime,
              'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true
          GROUP BY
            user_id,
            time_start
          ORDER BY
            time_start ASC,
            user_id ASC;
        SQL

        data = ActiveRecord::Base.connection.execute(sql).to_a

        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'leadspeed',
              quantifiable_id: stat_data['user_id'],
              quantifiable_type: 'User',
              resolution: resolution,
              value: stat_data['avg_leadtime'],
              time_start: stat_data['time_start']
            )
          rescue
            # NOOP: this is a duplicate
            next
          end
        end
        true
      end

      def self.generate_property_leadspeed(property:, resolution: 60, time_start:, time_end: nil)
        return true if property.users.active.empty?

        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            CEIL(avg(lead_time)) AS avg_leadtime,
              'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true AND
            user_id IN (#{property.users.pluck(:id).map{|i| "'#{i}'"}.join(',')})
          GROUP BY
            time_start
          ORDER BY
            time_start ASC;
        SQL

        data = ActiveRecord::Base.connection.execute(sql).to_a
        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'leadspeed',
              quantifiable_id: property.id,
              quantifiable_type: 'Property',
              resolution: resolution,
              value: stat_data['avg_leadtime'],
              time_start: stat_data['time_start']
            )
          rescue
            # NOOP: this is a duplicate
            next
          end
        end
        true
      end

      def self.generate_team_leadspeed(team:, resolution: 60, time_start:, time_end: nil)
        return true if team.members.empty?

        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            CEIL(avg(lead_time)) AS avg_leadtime,
              'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true AND
            user_id IN (#{team.members.pluck(:id).map{|i| "'#{i}'"}.join(',')})
          GROUP BY
            time_start
          ORDER BY
            time_start ASC;
        SQL

        data = ActiveRecord::Base.connection.execute(sql).to_a
        data.each do |stat_data|
          begin
            Statistic.create(
              fact: 'leadspeed',
              quantifiable_id: team.id,
              quantifiable_type: 'Team',
              resolution: resolution,
              value: stat_data['avg_leadtime'],
              time_start: stat_data['time_start']
            )
          rescue
            # NOOP: this is a duplicate
            next
          end
        end
        true
      end

      def self.rollup_all_leadspeed_intervals
        self.rollup_leadspeed(interval: :day, time_start: 1.day.ago.beginning_of_day)
        self.rollup_leadspeed(interval: :week, time_start: 1.week.ago.beginning_of_week)
        self.rollup_leadspeed(interval: :month, time_start: 1.month.ago.beginning_of_month)
        self.rollup_leadspeed(interval: :year, time_start: 1.year.ago.beginning_of_year)
      end

      def self.rollup_leadspeed(interval: ,time_start:)
        case interval
        when :day
          resolution = 1.hour / 60
          new_resolution = 1.day / 60
          time_start = time_start.beginning_of_day
          time_end = time_start + 1.day
        when :week
          resolution = 1.day / 60
          new_resolution = 1.week / 60
          time_start = time_start.beginning_of_week
          time_end = time_start + 1.week
        when :month
          resolution = 1.week / 60
          new_resolution = 1.month / 60
          time_start = time_start.beginning_of_month
          time_end = time_start + 1.month
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
            CEIL(avg(value)) AS avg_leadtime
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
              fact: 'leadspeed',
              quantifiable_id: stat_data['quantifiable_id'],
              quantifiable_type: stat_data['quantifiable_type'],
              resolution: new_resolution.to_i,
              value: stat_data['avg_leadtime'],
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
