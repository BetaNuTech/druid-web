class ChangeMessageThreadidToString < ActiveRecord::Migration[5.1]
  def change
    change_column :messages, :threadid, :string
  end
end
