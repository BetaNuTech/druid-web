class AddLeadConversionDate < ActiveRecord::Migration[5.1]
  def change
    add_column :leads, :conversion_date, :datetime
  end
end
