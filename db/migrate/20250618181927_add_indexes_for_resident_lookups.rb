class AddIndexesForResidentLookups < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  
  def change
    # Add indexes for resident_details lookups
    add_index :resident_details, :phone1, algorithm: :concurrently unless index_exists?(:resident_details, :phone1)
    add_index :resident_details, :phone2, algorithm: :concurrently unless index_exists?(:resident_details, :phone2)
    add_index :resident_details, :email, algorithm: :concurrently unless index_exists?(:resident_details, :email)
    
    # Add composite index for residents property lookup
    add_index :residents, [:property_id, :status], algorithm: :concurrently unless index_exists?(:residents, [:property_id, :status])
  end
end
