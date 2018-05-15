json.extract! message, :id, :threadid, :senderid, :recipientid, :subject, :body,
  :delivered_at, :messageable_id, :messageable_type, :user_id, :state,
  :message_template_id, :created_at, :updated_at
json.url message_url(message, format: :json)
