class AddLeaConversationUrlToLeads < ActiveRecord::Migration[6.1]
  def change
    add_column :leads, :lea_conversation_url, :string
    add_index :leads, :lea_conversation_url, where: "lea_conversation_url IS NOT NULL"
  end
end
