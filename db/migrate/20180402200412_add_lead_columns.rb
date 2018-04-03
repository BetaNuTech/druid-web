class AddLeadColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :remoteid, :string
    add_column :leads, :middle_name, :string

    add_index :leads, :remoteid
  end
end
