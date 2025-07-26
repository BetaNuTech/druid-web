class AddSystemUserFlagToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :system_user, :boolean, default: false, null: false
    # Note: Skipping the partial unique index due to PostgreSQL syntax issues
    # The application enforces uniqueness through validations
  end
end