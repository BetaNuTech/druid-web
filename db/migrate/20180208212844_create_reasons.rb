class CreateReasons < ActiveRecord::Migration[5.1]
  def change
    create_table :reasons, id: :uuid do |t|
      t.string :name
      t.string :description
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
