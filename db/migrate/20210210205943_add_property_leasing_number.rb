class AddPropertyLeasingNumber < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :leasing_phone, :string
  end
end
