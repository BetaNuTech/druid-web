class CreateRentalTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :rental_types, id: :uuid do |t|
      t.string :name

      t.timestamps
    end
  end
end
