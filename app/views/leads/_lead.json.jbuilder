json.extract! lead, :id, :remoteid, :title, :first_name, :middle_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone2, :fax, :email, :created_at, :updated_at, :priority
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
    json.nil?
  end
end
json.comments do
  json.array! lead.comments.comment.order(created_at: :desc).limit(5), partial: "notes/note", as: :note
end
json.url lead_url(id: lead.id, format: :json)
json.web_url lead_url(id: lead.id, format: :html)
