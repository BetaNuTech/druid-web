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

      def task_calendar_expiration
        last_timestamp = ( scheduled_actions.select(:updated_at).order(updated_at: :desc).first&.updated_at || DateTime.current ).to_i
        if last_timestamp < (DateTime.current - 12.hours).to_i
          # Return current epoch if the last task update time was over 12h ago
          DateTime.current.to_i
        else
          last_timestamp
        end
      end

      def weekly_score
        compliances.
          where(completed_at: (Date.current.beginning_of_week)..DateTime.current).
          sum(:score)
      end

      def tasks_completed(start_date: (Date.current - 7.days).beginning_of_day, end_date: DateTime.current)
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
      def task_completion_rate(start_date: (Date.current - 7.days).beginning_of_day, end_date: DateTime.current)
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

      def showing_rate(start_date: (Date.current - 7.days).beginning_of_day, end_date: DateTime.current)
        claimed_leads_count = self.leads.includes(:transitions).
          where(lead_transitions: {created_at: start_date..end_date, current_state: 'prospect'}).
          count.to_f
        showings = self.scheduled_actions.includes(:engagement_policy_action_compliance).
          where(scheduled_actions: {lead_action_id: LeadAction.showing&.id},
                engagement_policy_action_compliances: { completed_at: start_date..end_date}).
          count.to_f

        if claimed_leads_count == 0
          return 1.0
        else
          if showings < 1
            return 0.0
          end
        end

        return (showings/claimed_leads_count).round(2)
      end

      def team_tasks
        user_ids = PropertyUser.where(property_id: self.property_ids).pluck(:user_id).uniq
        ScheduledAction.where(user_id: user_ids, target_type: 'Lead')
      end


    end
  end
end
