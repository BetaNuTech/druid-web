module Properties
  class Scheduler
    DEFAULT_APPOINTMENT_LENGTH = 30

    attr_reader :property, :appointment_length

    def initialize(property)
      @property = property
      @appointment_length = DEFAULT_APPOINTMENT_LENGTH
    end

    def availability(category: 'showing', start_time: Time.current, end_time: nil, appt_length: DEFAULT_APPOINTMENT_LENGTH)
      end_time ||= Time.current + 1.week
      possible_conflicts = showings(start_time: start_time, end_time: end_time).map do |task|
        task_start = next_30m(task.schedule.to_datetime) - 30.minutes
        task_end = task_start + ( [( task.schedule.duration || 0 ), 30].min).minutes
        [task_start, task_end]
      end
      possible_times = all_possible_times(start_time:, end_time:).
        select{ |t|
                  property.office_open?(t) &&
                  !possible_conflicts.any?{ |window|
                    end_of_time_window = t.first + appt_length.minutes - 1
                    conflict?(t, window) || conflict?([end_of_time_window, end_of_time_window], window)
                  }
               }
    end
    
    private

    def showings(start_time:, end_time: )
      join_sql =<<~EOSQL
        INNER JOIN leads ON leads.id = scheduled_actions.target_id AND scheduled_actions.target_type = 'Lead' AND leads.property_id = '#{@property.id}'
      EOSQL
      ScheduledAction.joins(join_sql).includes(:schedule).where(
        scheduled_actions: {lead_action_id: LeadAction.showing.id},
        schedules: { date: start_time.to_date...( end_time.to_date + 1.day ) }
      )
    end

    def conflict?(time, window)
      adj_time = time.first
      adj_time >= window.first && adj_time <= window.last
    end

    def all_possible_times(start_time:, end_time:)
      if end_time > start_time.end_of_day + 1.month
        end_time = start_time.end_of_day + 1.month
      end
      all_times = []
      cursor = next_30m(start_time)
      while(cursor <= end_time)
        all_times << [cursor, cursor + 30.minutes]
        cursor += 30.minutes
      end
      all_times
    end

    # Set cursor to the next increment of 30m
    def next_30m(timestamp)
      cursor = timestamp.beginning_of_hour + 30.minutes
      if cursor < timestamp
        cursor = cursor + 30.minutes
      end
      cursor
    end

  end
end
