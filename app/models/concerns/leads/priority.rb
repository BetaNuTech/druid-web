module Leads
  module Priority
    extend ActiveSupport::Concern

    included do

      enum priority: { zero: 0, low: 1, medium: 2, high: 3, urgent: 4 }, _prefix: :priority

      def self.set_priorities
        errors = []
        skope = self.active
        skope.each do |lead|
          begin
            old_priority = lead.priority
            lead.calculate_priority
            if lead.changed?
              lead.save
              msg = "Lead Priority Updater: Lead[#{lead.id}] priority updated #{old_priority} => #{lead.priority}"
              Rails.logger.warn msg
              puts msg if Rails.env.development?
            else
              msg = "Lead Priority Updater: Lead[#{lead.id}] priority unchanged"
              Rails.logger.warn msg
              puts msg if Rails.env.development?
            end
          rescue => e
            msg = "Lead Priority Updater: Error calculating/setting Lead[#{lead.id}] Priority. #{e}"
            errors << msg
            Rails.logger.warn msg
          end
        end
        had_errors = errors.present?
        unless Rails.env.production?
          puts errors.inspect if had_errors
        end
        return !had_errors
      end

      def estimated_priority
        score = state_priority_score + last_contact_score + task_deadline_score
        score = [score, 5].min - 1
        return score
      end

      def calculate_priority
        self.priority = Lead.priorities.key(estimated_priority)
      end

      def state_priority_score
        state_scores = {
          open: 5,
          prospect: 3,
          application: 2,
          approved: 2,
          denied: 2,
          movein: 1,
          resident: 0,
          exresident: 0,
          disqualified: 0,
          abandoned: 0
        }

        score = state_scores.fetch(state.to_sym, 0)
        return score
      end

      def last_contact_score
        elapsed = [ ( DateTime.now.to_i - ( last_comm.to_i || first_comm.to_i || DateTime.now.to_i) ), 1].max.to_f
        ratio = [ ( elapsed / 7.0.days.to_f ), 1.0 ].min
        score = ( 3.0 * ratio ).round
        return score
      end

      def task_deadline_score
        last_action_due = scheduled_actions.incomplete.includes(:schedule).
          order("schedules.date DESC, schedules.time DESC").
          limit(1).first

        return 0.0 unless last_action_due.present?

        elapsed = [ (DateTime.now.to_i - last_action_due.created_at.to_i), 1 ].max.to_f
        duration = [( last_action_due.schedule.to_datetime.to_i - last_action_due.created_at.to_i ), 1].max.to_f
        ratio = [(elapsed / duration), 1.0].min
        score = (3.0 * ratio ).round
        return score
      end


    end

  end
end

