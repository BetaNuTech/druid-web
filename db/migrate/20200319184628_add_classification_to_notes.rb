class AddClassificationToNotes < ActiveRecord::Migration[6.0]
  def self.up
    add_column :notes, :classification, :integer, default: 0
    add_index :notes, :classification

    Note.where(user_id: nil).update_all(classification: 'system')
  end

  def self.down
    remove_index :notes, :classification
    remove_column :notes, :classification
  end

end
