module ScheduledActions
  module Schedule
    extend ActiveSupport::Concern

    class_methods do
      def having_schedule
        self.joins("INNER JOIN schedules ON schedules.schedulable_type = 'ScheduledAction' AND schedules.schedulable_id = scheduled_actions.id")
      end

      def upcoming
        return self.incomplete.having_schedule.
          where("schedules.date > ?", Date.today).
          sorted_by_due_asc
        #return self.incomplete.having_schedule.
          #sorted_by_due_asc
      end

      def due_today
        return self.incomplete.having_schedule.
          where("schedules.date <= ?", Date.today).
          sorted_by_due_asc
      end

      def previous
        skope = self.having_schedule.complete
        return skope
      end

      def sorted_by_due_asc
        skope = self.having_schedule.
          order("schedules.date ASC, schedules.time ASC")
      end

      def with_start_date(date)
        start_date = ( Date.parse(date).beginning_of_month rescue (Date.today.beginning_of_month) )
        self.having_schedule.
          where("schedules.date >= ?", start_date).
          or(self.having_schedule.where(state: 'pending'))
      end

    end
  end
end
