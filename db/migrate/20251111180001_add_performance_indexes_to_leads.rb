class AddPerformanceIndexesToLeads < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    # Indexes for leads table
    add_index :leads, :first_comm, algorithm: :concurrently unless index_exists?(:leads, :first_comm)
    add_index :leads, :last_comm, algorithm: :concurrently unless index_exists?(:leads, :last_comm)
    add_index :leads, :user_id, algorithm: :concurrently unless index_exists?(:leads, :user_id)
    add_index :leads, :lead_source_id, algorithm: :concurrently unless index_exists?(:leads, :lead_source_id)
    add_index :leads, [:property_id, :state, :first_comm], algorithm: :concurrently,
              name: 'index_leads_on_property_state_first_comm' unless index_exists?(:leads, [:property_id, :state, :first_comm])

    # Critical index for lead_preferences join performance
    add_index :lead_preferences, :lead_id, algorithm: :concurrently unless index_exists?(:lead_preferences, :lead_id)
    add_index :lead_preferences, :beds, algorithm: :concurrently unless index_exists?(:lead_preferences, :beds)
    add_index :lead_preferences, :move_in, algorithm: :concurrently unless index_exists?(:lead_preferences, :move_in)

    # Index for notes (comments) queries
    add_index :notes, [:notable_type, :notable_id, :classification, :created_at], algorithm: :concurrently,
              name: 'index_notes_on_notable_and_classification' unless index_exists?(:notes, [:notable_type, :notable_id, :classification, :created_at])
  end
end
