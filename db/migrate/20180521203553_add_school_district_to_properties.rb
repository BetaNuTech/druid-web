class AddSchoolDistrictToProperties < ActiveRecord::Migration[5.1]
  def change
    add_column :properties, :school_district, :string
  end
end
