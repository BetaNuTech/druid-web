class AddApplicationUrlToProperty < ActiveRecord::Migration[5.2]
  def change
    add_column :properties, :application_url, :string
  end
end
