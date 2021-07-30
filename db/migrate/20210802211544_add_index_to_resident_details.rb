class AddIndexToResidentDetails < ActiveRecord::Migration[6.1]
  def change
    add_index :resident_details, [:phone1, :phone2, :email], name: :resident_details_contact
  end
end
