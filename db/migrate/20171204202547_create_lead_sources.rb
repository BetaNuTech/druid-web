class CreateLeadSources < ActiveRecord::Migration[5.1]
  def change
    create_table :lead_sources, id: :uuid do |t|
      t.string :name
      t.boolean :incoming
      t.string :slug
      t.boolean :active

      t.timestamps
    end
  end
end
