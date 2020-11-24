class AddWorkingHoursToProperty < ActiveRecord::Migration[6.0]
  def change
    add_column :properties, :working_hours, :jsonb
  end
end
