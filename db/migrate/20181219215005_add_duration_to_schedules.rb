class AddDurationToSchedules < ActiveRecord::Migration[5.2]
  def self.up
    add_column :schedules, :duration, :integer
    add_column :schedules, :end_time, :time
  end

  def self.down
    remove_column :schedules, :duration
    remove_column :schedules, :end_time
  end
end
