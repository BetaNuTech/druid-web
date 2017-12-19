class LeadAddPhoneEmail < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :phone1, :string
    add_column :leads, :phone2, :string
    add_column :leads, :fax, :string
    add_column :leads, :email, :string
  end
end
