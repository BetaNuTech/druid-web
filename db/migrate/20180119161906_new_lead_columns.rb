class NewLeadColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :phone1_type, :string
    add_column :leads, :phone2_type, :string
    add_column :leads, :phone1_tod, :string
    add_column :leads, :phone2_tod, :string
    add_column :leads, :dob, :datetime
    add_column :leads, :id_number, :string
    add_column :leads, :id_state, :string
  end
end
