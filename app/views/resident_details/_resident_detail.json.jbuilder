json.extract! resident_detail, :id, :resident_id, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :email, :ssn, :id_number, :id_state, :created_at, :updated_at
json.url resident_detail_url(resident_detail, format: :json)
