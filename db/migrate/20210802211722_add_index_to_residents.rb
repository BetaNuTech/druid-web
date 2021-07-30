class AddIndexToResidents < ActiveRecord::Migration[6.1]
  def change
    add_index :residents, [:first_name, :last_name], name: :residents_name
  end
end
