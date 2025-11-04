class FixActiveStorageForUuids < ActiveRecord::Migration[6.1]
  def up
    # Change record_id from bigint to string to support UUID primary keys
    change_column :active_storage_attachments, :record_id, :string, null: false
  end

  def down
    # This is dangerous - only works if no UUID attachments exist
    change_column :active_storage_attachments, :record_id, :bigint, null: false
  end
end