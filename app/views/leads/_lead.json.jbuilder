json.extract! lead, :id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone2, :fax, :email, :created_at, :updated_at
json.preference do
  json.partial! 'leads/preference', locals: {preference: lead.preference}
end
json.url lead_url(id: lead.id, format: :json)
