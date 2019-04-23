class AddDefaultToLeadPhone1Type < ActiveRecord::Migration[5.2]
  def change
    change_column_default :leads, :phone1_type, 'Cell'
  end
end
