module Users
  class ActivityReport

    def initialize(property)
      @property = property
      @skope = property.users.active
      @start_date = 1.month.ago.beginning_of_month
      @end_date = DateTime.current
    end

    def call
      {
        start_date: @start_date.to_date,
        end_date: @end_date.to_date,
        property_name: @property.name,
        property_id: @property.id,
        logins: login_stats,
        leads: lead_stats,
        messages: message_stats,
        tasks: task_stats,
        users: @skope.inject({}){|memo, obj| memo[obj.id] = obj; memo}
      }
    end

    def login_stats
      stats = {}
      @skope.each do |user|
        stats[user.id] = {
          last: ( user.current_sign_in_at || user.last_sign_in_at )&.to_datetime || 'None',
          history: user.login_timestamps.reverse.map{|t| t.to_date}.compact.uniq
        }
      end
      stats
    end

    def lead_stats
      stats = {}
      @skope.each do |user|
        stats[user.id] = {
          claimed: lead_transitions(user: user, last_state: 'open', current_state: 'prospect',
                                    start_date: @start_date, end_date: @end_date).count,
          abandoned: lead_transitions(user: user, last_state: Leads::StateMachine::CLAIMED_STATES, current_state: 'abandoned',
                                      start_date: @start_date, end_date: @end_date).count,
          disqualified: lead_transitions(user: user, last_state: Leads::StateMachine::CLAIMED_STATES , current_state: 'disqualified',
                                         start_date: @start_date, end_date: @end_date).count,
          showings: showings(user: user, start_date: @start_date, end_date: @end_date),
          applications: lead_transitions(user: user, last_state: Leads::StateMachine::CLAIMED_STATES , current_state: 'application',
                                         start_date: @start_date, end_date: @end_date).count,
        }
      end
      stats
    end

    def lead_transitions(user:, start_date:, end_date:, last_state:, current_state:)
      LeadTransition.includes(:lead).where(
        leads: { user_id: user.id},
        created_at: start_date..end_date,
        last_state: last_state,
        current_state: current_state
      )
    end

    def showings(user:, start_date: nil, end_date: nil)
      user.scheduled_actions.showings.
        where(completed_at: start_date..end_date).
        count
    end

    def message_stats
      stats = {}
      @skope.each do |user|
        stats[user.id] = {
          sent: user.messages.outgoing.where(created_at: @start_date..@end_date).count
        }
      end
      stats
    end

    def task_stats
      stats = {}
      @skope.each do |user|
        completed_items = user.engagement_policy_action_compliances.
          where(state: [:completed, :completed_retry] ,completed_at: (@start_date..@end_date) ).
          order(completed_at: :desc)
        stats[user.id] = {
          completed: completed_items.count,
          last_completed: completed_items.first&.completed_at
        }
      end
      stats
    end
  end
end
