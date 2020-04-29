class AddClassificationToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :classification, :integer, default: 0
  end
end
