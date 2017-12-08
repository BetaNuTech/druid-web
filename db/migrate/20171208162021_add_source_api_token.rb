class AddSourceApiToken < ActiveRecord::Migration[5.1]
  def change
    add_column :lead_sources, :api_token, :string
  end
end
