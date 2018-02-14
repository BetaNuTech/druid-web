json.extract! note, :id, :user_id, :lead_action_id, :reason_id, :notable_id, :notable_type, :content, :created_at, :updated_at
json.url note_url(note, format: :json)
