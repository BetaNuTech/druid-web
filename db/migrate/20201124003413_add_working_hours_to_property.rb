class AddWorkingHoursToProperty < ActiveRecord::Migration[6.0]
  def up
    # First add the column without any data conversion
    add_column :properties, :working_hours, :jsonb

    # If you need to populate the column with default data, do it separately
    # with proper error handling
    begin
      # Example of adding default working hours as JSON (adjust as needed)
      execute <<-SQL
        UPDATE properties 
        SET working_hours = '{"monday":{"start":"9:00","end":"17:00","enabled":true},"tuesday":{"start":"9:00","end":"17:00","enabled":true},"wednesday":{"start":"9:00","end":"17:00","enabled":true},"thursday":{"start":"9:00","end":"17:00","enabled":true},"friday":{"start":"9:00","end":"17:00","enabled":true},"saturday":{"start":"9:00","end":"17:00","enabled":false},"sunday":{"start":"9:00","end":"17:00","enabled":false}}'::jsonb
        WHERE working_hours IS NULL
      SQL
    rescue => e
      puts "Failed to populate default working hours: #{e.message}"
      # Continue without failing the entire migration
    end
  end

  def down
    remove_column :properties, :working_hours
  end
end
