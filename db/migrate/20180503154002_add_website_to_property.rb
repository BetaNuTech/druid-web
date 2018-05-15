class AddWebsiteToProperty < ActiveRecord::Migration[5.1]
  def change
    add_column :properties, :website, :string
  end
end
