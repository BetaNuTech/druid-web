json.extract! lead, :id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone2, :fax, :email, :created_at, :updated_at, :priority
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
json.url lead_url(id: lead.id, format: :json)
