class AddAmenitiesToProperties < ActiveRecord::Migration[5.1]
  def change
    add_column :properties, :amenities, :text
  end
end
