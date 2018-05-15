class AddTokenToMessageDeliveryAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :message_delivery_adapters, :api_token, :string
    add_index :message_delivery_adapters, :api_token

    MessageDeliveryAdapter.all.each{|mda| mda.save!}
  end
end
