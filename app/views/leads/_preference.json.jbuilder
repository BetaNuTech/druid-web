json.extract! preference, :min_area, :max_area, :min_price, :max_price, :move_in, :baths, :beds, :smoker, :washerdryer, :notes, :unit_type_id
json.unit_type_name preference.unit_type.try(:name)

