module ScheduledActions
  module Schedule
    extend ActiveSupport::Concern

    class_methods do
      def having_schedule
        self.joins("INNER JOIN schedules ON schedules.schedulable_type = 'ScheduledAction' AND schedules.schedulable_id = scheduled_actions.id")
      end

      def upcoming
        return self.incomplete.having_schedule
      end

      def previous
        skope = self.incomplete.having_schedule.
          where("schedules.date < ?", Date.today).
          or(self.having_schedule.complete)
        return skope
      end

      def self.with_start_date(date)
        start_date = ( Date.parse(date).beginning_of_month rescue (Date.today.beginning_of_month) )
        self.having_schedule.
          where("schedules.date >= ?", start_date).
          or(self.having_schedule.where(state: 'pending'))
      end

    end
  end
end
