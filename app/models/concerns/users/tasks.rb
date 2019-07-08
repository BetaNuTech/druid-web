module Users
  module Tasks
    extend ActiveSupport::Concern

    included do
      has_many :scheduled_actions
      has_many :compliances, class_name: 'EngagementPolicyActionCompliance'
      has_many :engagement_policy_action_compliances

      def score
        compliances.sum(:score)
      end

      alias total_score score

      def weekly_score
        compliances.
          where(completed_at: (Date.today.beginning_of_week)..DateTime.now).
          sum(:score)
      end

      def tasks_completed(start_date: (Date.today - 7.days).beginning_of_day, end_date: DateTime.now)
        ScheduledAction.includes(:engagement_policy_action_compliance).
          where( engagement_policy_action_compliances: {completed_at: start_date..end_date},
                scheduled_actions: {user_id: id} )
      end

      def tasks_pending
        ScheduledAction.includes(:engagement_policy_action_compliance).
          where( engagement_policy_action_compliances: {state: 'pending'},
                scheduled_actions: {user_id: id} )
      end

      # On-time Task completion rate
      def task_completion_rate(start_date: (Date.today - 7.days).beginning_of_day, end_date: DateTime.now)
        skope = ScheduledAction.includes(:engagement_policy_action_compliance).
          where(scheduled_actions: {user_id: id})
        due_actions = skope.where(engagement_policy_action_compliances: {expires_at: start_date..end_date})
        completed_actions = skope.
          where(engagement_policy_action_compliances: { completed_at: start_date..end_date}).
          where('engagement_policy_action_compliances.completed_at <= engagement_policy_action_compliances.expires_at')
        if due_actions == 0
          return 1.0
        else
          if completed_actions == 0
            return 0.0
          end
        end
        return (completed_actions.count.to_f / due_actions.count.to_f).round(2)
      end

    end
  end
end
