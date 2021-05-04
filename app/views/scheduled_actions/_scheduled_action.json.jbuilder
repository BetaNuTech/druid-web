json.extract! scheduled_action, :id, :user_id, :target_id, :target_type, :description, :completed_at, :state, :attempt, :created_at, :updated_at
json.set! :scheduled, scheduled_action.schedule.duration.present?
json.set! :completed, scheduled_action.is_completed?
json.set! :user, scheduled_action.user&.name
json.set! :lead_action, scheduled_action.lead_action&.name
json.set! :reason, scheduled_action.reason&.name
json.set! :start_time, scheduled_action.schedule&.to_datetime
json.set! :end_time, scheduled_action.schedule&.end_time_to_datetime
json.set! :schedule_description, scheduled_action&.schedule&.description
json.set! :article, scheduled_action.article&.name
json.set! :due, scheduled_action.due_today?
json.url scheduled_action_url(scheduled_action, format: :json)
json.web_url scheduled_action_url(scheduled_action)
