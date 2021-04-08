json.extract! preference, :min_area, :max_area, :price, :move_in_date, :baths, :beds, :smoker, :washerdryer, :notes, :unit_type_id, :email_allowed, :sms_allowed, :floorplan_name
json.unit_type_name preference.unit_type.try(:name)

