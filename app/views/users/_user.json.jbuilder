json.extract! user, :id, :email, :name_prefix, :first_name, :last_name, :office_phone, :cell_phone, :fax, :notes, :created_at, :updated_at
json.url user_url(user, format: :json)
