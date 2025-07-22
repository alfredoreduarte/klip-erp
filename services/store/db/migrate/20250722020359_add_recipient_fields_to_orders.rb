class AddRecipientFieldsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :recipient_name, :string
    add_column :orders, :recipient_phone, :string
    add_column :orders, :hide_prices, :boolean
    add_column :orders, :is_gift_order, :boolean
  end
end
