json.extract! property, :id, :name, :address1, :address2, :address3, :city, :state, :zip, :country, :organization, :contact_name, :phone, :maintenance_phone, :fax, :email, :units, :notes, :created_at, :updated_at
json.team property.team.try(:name)
json.team_id property.team_id
json.url property_url(property, format: :json)
