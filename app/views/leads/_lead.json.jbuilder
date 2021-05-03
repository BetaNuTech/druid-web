json.extract! lead, :id, :remoteid, :title, :first_name, :middle_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :last_comm_relative, :phone1, :phone2, :fax, :email, :created_at, :updated_at, :priority, :phone1_formatted, :phone2_formatted
json.preference do
  json.partial! 'leads/preference', locals: {preference: lead.preference}
end
json.property do
  if lead.property.present?
    json.partial! 'leads/property', locals: {property: lead.property, source: lead.source}
  else
    json.nil!
  end
end
json.user do
  if lead.user.present?
    json.extract! lead.user, :id, :name
  else
    json.id nil
    json.name 'Unclaimed'
  end
end
json.comments do
  json.array! lead.comments, partial: "notes/note", as: :note
end
json.roommates do
  json.array! lead.roommates, partial: "roommates/roommate", as: :roommate
end
json.tasks do
  json.array! lead.scheduled_actions, partial: "scheduled_actions/scheduled_action", as: :scheduled_action
end
json.url lead_url(id: lead.id, format: :json)
json.web_url lead_url(id: lead.id)
