class CreateSchedules < ActiveRecord::Migration[5.1]
  def self.up
    create_table :schedules, id: :uuid do |t|
      #t.references :schedulable, polymorphic: true
      t.string :schedulable_type
      t.uuid :schedulable_id

      t.date :date
      t.time :time

      t.string :rule
      t.string :interval

      t.text :day
      t.text :day_of_week

      t.datetime :until
      t.integer :count

      t.timestamps
    end
  end

  def self.down
    drop_table :schedules
  end
end
