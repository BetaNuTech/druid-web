module Statistics
  module LeadSpeed
    extend ActiveSupport::Concern

    included do
      LEADSPEED_EXCLUDED_LEAD_STATES = [ 'resident', 'exresident', 'disqualified' ]
      LEADSPEED_EXCLUDED_SOURCES = ['YardiVoyager']

      def self.lead_speed_grade(minutes)
        case minutes
        when (0..29)
          'A'
        when (30..120)
          'B'
        when nil
          'NA'
        else
          'C'
        end
      end

      def self.lead_speed_grade_for(obj, interval: :week, time_start:)
        skope = Statistic.where(quantifiable: obj, time_start: time_start).leadspeed
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

      def self.backfill_leadspeed(time_start:, time_end: )
        resolution = 60
        cursor = time_start.beginning_of_hour
        while cursor <= time_end
          cursor_end = cursor + resolution.minutes
          self.generate_leadspeed(resolution: resolution, time_start: cursor, time_end: cursor_end)
          Property.active.each do |property|
            self.generate_property_leadspeed(property: property, resolution: resolution, time_start: cursor, time_end: cursor_end)
          end
          Team.all.each do |team|
            self.generate_team_leadspeed(team: team, resolution: resolution, time_start: cursor, time_end: cursor_end)
          end
          cursor += resolution.minutes
        end

        cursor = time_start.beginning_of_day
        while cursor <= time_end
          self.rollup_leadspeed(interval: :day, time_start: cursor.beginning_of_day)
          cursor += 1.day
        end

        cursor = time_start.beginning_of_week
        while cursor <= time_end
          self.rollup_leadspeed(interval: :week, time_start: cursor.beginning_of_week)
          cursor += 1.week
        end

        cursor = time_start.beginning_of_month
        while cursor <= time_end
          self.rollup_leadspeed(interval: :month, time_start: cursor.beginning_of_month)
          cursor += 1.month
        end

        cursor = time_start.beginning_of_year
        while cursor <= time_end
          self.rollup_leadspeed(interval: :year, time_start: cursor.beginning_of_year)
          cursor += 1.month
        end
      end

      # Generate LeadSpeed statistics
      #
      # resolution: Integer (minutes)
      # time_start: Time
      # time_end: Time (default: Now)
      def self.generate_leadspeed(resolution: 60, time_start:, time_end: nil)
        time_end ||= Time.now

        data = Statistic.contact_events_for_user_leadspeed(resolution: resolution, time_start: time_start, time_end: time_end)

        data.to_a.each do |stat_data|
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

      def self.contact_events_for_user_leadspeed(resolution: 60, time_start:, time_end: nil)
        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            contact_events.user_id,
            CEIL(avg(lead_time)) AS avg_leadtime,
            'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          INNER JOIN leads
            ON leads.id = contact_events.lead_id
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true AND
            #{Statistic.leadspeed_exclusion_sql}
          GROUP BY
            contact_events.user_id,
            time_start
          ORDER BY
            time_start ASC,
            contact_events.user_id ASC;
        SQL

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.rolling_month_property_leadspeed(property)
        return true if property.users.active.empty?

        resolution = 1.week / 60
        time_start = 1.month.ago
        time_end = Time.now

        sql = <<~SQL
          SELECT
            quantifiable_id,
            quantifiable_type,
            CEIL(avg(value)) AS avg_leadtime
          FROM
            statistics
          WHERE
            fact = 0 AND
            quantifiable_type = 'Property' AND
            quantifiable_id = '#{property.id}' AND
            resolution = #{resolution.to_i} AND
            time_start BETWEEN '#{time_start}' AND '#{time_end}'
          GROUP BY
            quantifiable_id,
            quantifiable_type;
        SQL

        data = ActiveRecord::Base.connection.execute(sql).to_a
        data.first&.fetch('avg_leadtime', nil)
      end

      def self.rolling_month_property_leadspeed_grade(property)
        Statistic.lead_speed_grade(self.rolling_month_property_leadspeed(property))
      end

      def self.generate_property_leadspeed(property:, resolution: 60, time_start: , time_end: nil)
        return true if property.users.active.empty?

        time_end ||= Time.now

        data = Statistic.contact_events_for_property_leadspeed(
          property: property, resolution: resolution, time_start: time_start, time_end: time_end)

        data.to_a.each do |stat_data|
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

      def self.contact_events_for_property_leadspeed(property:, resolution: 60, time_start:, time_end: nil)
        return ContactEvent.where('1=0') if property.users.empty?

        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            CEIL(avg(lead_time)) AS avg_leadtime,
              'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          INNER JOIN leads
            ON leads.id = contact_events.lead_id
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true AND
            contact_events.user_id IN (#{property.users.pluck(:id).map{|i| "'#{i}'"}.join(',')}) AND
            #{Statistic.leadspeed_exclusion_sql}
          GROUP BY
            time_start
          ORDER BY
            time_start ASC;
        SQL

        ActiveRecord::Base.connection.execute(sql)
      end

      def self.generate_team_leadspeed(team:, resolution: 60, time_start:, time_end: nil)
        return true if team.members.empty?

        data = Statistic.contact_events_for_team_leadspeed(team: team, resolution: resolution, time_start: time_start, time_end: time_end)

        data.to_a.each do |stat_data|
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

      def self.contact_events_for_team_leadspeed(team:, resolution: 60, time_start:, time_end: nil)
        return ContactEvent.where('1=0') if team.members.empty?

        time_end ||= Time.now

        sql = <<~SQL
          SELECT
            CEIL(avg(lead_time)) AS avg_leadtime,
              'epoch'::timestamptz + '#{resolution} minutes'::INTERVAL * (EXTRACT(epoch FROM timestamp)::int4 / #{resolution * 60}) AS time_start
          FROM
            contact_events
          INNER JOIN leads
            ON leads.id = contact_events.lead_id
          WHERE
            timestamp BETWEEN '#{time_start}' AND '#{time_end}' AND
            first_contact = true AND
            contact_events.user_id IN (#{team.members.pluck(:id).map{|i| "'#{i}'"}.join(',')}) AND
            #{Statistic.leadspeed_exclusion_sql}
          GROUP BY
            time_start
          ORDER BY
            time_start ASC;
        SQL

        ActiveRecord::Base.connection.execute(sql)
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

      def self.leadspeed_exclusion_sql
        out_sql = []

        # Exclude non-leads
        excluded_lead_states_sql = "leads.state NOT IN (#{LEADSPEED_EXCLUDED_LEAD_STATES.map{|s| "'#{s}'"}.join(', ')})"
        out_sql << excluded_lead_states_sql

        # Include only real leads or unclassified leads
        out_sql << "( leads.classification = 0 OR leads.classification IS NULL )"

        # Exclude some sources (especially Yardi Voyager which is prone to delays)
        excluded_lead_source_ids = LeadSource.where(slug: LEADSPEED_EXCLUDED_SOURCES).pluck(:id)
        if excluded_lead_source_ids.any?
          excluded_lead_sources_sql = "leads.lead_source_id NOT IN (#{excluded_lead_source_ids.map{|s| "'#{s}'"}.join(', ')})"
          out_sql << excluded_lead_sources_sql
        end

        # Exclude contact events with excessive lead time (indicating a system problem not a person problem)
        out_sql << "contact_events.lead_time < #{2.days.to_i / 60}"

        out_sql.join(' AND ')
      end
    end
  end
end
