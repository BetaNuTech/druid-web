json.extract! lead, :id, :user_id, :lead_source_id, :lead_preferences_id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :created_at, :updated_at
json.url lead_url(lead, format: :json)
