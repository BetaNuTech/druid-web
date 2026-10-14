class AddRelationshipAndYardiStatusToResidents < ActiveRecord::Migration[6.1]
  def change
    add_column :residents, :relationship, :string
    add_column :residents, :yardi_status, :string
  end
end
