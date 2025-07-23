class AddMissingFieldsToOrders < ActiveRecord::Migration[7.2]
  def change
    add_column :orders, :customer_surname, :string
    add_column :orders, :shipping_city, :string
    add_column :orders, :shipping_notes, :text
    add_column :orders, :payment_method, :string
    add_column :orders, :delivery_date, :date
    add_column :orders, :delivery_time_start, :time
    add_column :orders, :delivery_time_end, :time
  end
end
