module ScheduledActions
  module Schedule
    extend ActiveSupport::Concern

    included do
      before_create :schedule_time_hack! # HACK HACK HACK

      def schedule_time_hack!
        # HACK HACK HACK
        ### Schedulable incorrectly converts to UTC for DB storage, off by one hour 
        ### This magically fixes the problem
        schedule.time = schedule.time if schedule.present?
      end
    end

    class_methods do
      def having_schedule
        self.joins("INNER JOIN schedules ON schedules.schedulable_type = 'ScheduledAction' AND schedules.schedulable_id = scheduled_actions.id")
      end

      def upcoming
        return incomplete.having_schedule.
          where("schedules.date >= ?", Date.current)
      end

      def upcoming_or_incomplete
        return upcoming.or(incomplete.having_schedule).
                sorted_by_due_asc
      end

      def due_today
        return incomplete.having_schedule.
          where("schedules.date <= ?", Date.current).
          sorted_by_due_asc
      end

      def previous
        skope = self.having_schedule.complete
        return skope
      end

      def previous_month
        previous.where("schedules.date >= ? AND schedules.date <= ?", 1.month.ago.beginning_of_day, Date.current)
      end

      def sorted_by_due_asc
        skope = self.having_schedule.
          order("schedules.date ASC, schedules.time ASC")
      end

      def sorted_by_due_desc
        skope = self.having_schedule.
          order("schedules.date DESC, schedules.time DESC")
      end

      def with_start_date(date)
        start_date = ( Date.parse(date).beginning_of_month rescue (Date.current.beginning_of_month) )
        self.having_schedule.
          where("schedules.date >= ?", start_date).
          or(self.having_schedule.where(state: 'pending'))
      end

    end
  end
end
