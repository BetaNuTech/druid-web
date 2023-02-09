class AddCompanyAndCompanyTitleToLeads < ActiveRecord::Migration[6.1]
  def change
    add_column :leads, :company, :string
    add_column :leads, :company_title, :string
  end
end
