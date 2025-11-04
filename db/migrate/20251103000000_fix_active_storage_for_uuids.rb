class FixActiveStorageForUuids < ActiveRecord::Migration[6.1]
  def up
    # Clean up orphaned attachments that point to non-existent records
    # This prevents type mismatch errors after changing column type
    say_with_time "Removing orphaned ActiveStorage attachments" do
      # Find orphaned Property attachments
      execute <<-SQL
        DELETE FROM active_storage_attachments
        WHERE record_type = 'Property'
        AND NOT EXISTS (
          SELECT 1 FROM properties
          WHERE properties.id::text = active_storage_attachments.record_id::text
        );
      SQL

      # Find orphaned UserProfile attachments
      execute <<-SQL
        DELETE FROM active_storage_attachments
        WHERE record_type = 'UserProfile'
        AND NOT EXISTS (
          SELECT 1 FROM user_profiles
          WHERE user_profiles.id::text = active_storage_attachments.record_id::text
        );
      SQL
    end

    # Change record_id from bigint to string to support UUID primary keys
    # This allows ActiveStorage to work with models that use UUID primary keys
    say_with_time "Converting record_id from bigint to string" do
      change_column :active_storage_attachments, :record_id, :string, null: false
    end
  end

  def down
    # Note: This rollback is dangerous and should only be used in development
    # It will fail if any UUID attachments exist
    change_column :active_storage_attachments, :record_id, :bigint, null: false
  end
end