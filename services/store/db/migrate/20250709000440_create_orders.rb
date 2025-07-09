class CreateOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :orders do |t|
      t.string :order_number, null: false
      t.string :short_link_token, null: false
      t.string :status, default: 'pending'
      t.string :channel, null: false # 'whatsapp', 'phone', 'web', 'pos'
      t.string :customer_name
      t.string :customer_phone
      t.string :customer_email
      t.text :customer_notes
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.decimal :cost_of_goods, precision: 10, scale: 2, default: 0
      t.string :currency, default: 'USD'
      t.datetime :order_date
      t.datetime :shipped_date
      t.datetime :delivered_date
      t.text :shipping_address
      t.text :billing_address
      t.string :shipping_method
      t.string :tracking_number
      t.boolean :gift_wrap, default: false
      t.decimal :gift_wrap_cost, precision: 10, scale: 2, default: 0
      t.text :gift_message
      t.datetime :delivery_window_start
      t.datetime :delivery_window_end
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, :short_link_token, unique: true
    add_index :orders, :status
    add_index :orders, :channel
    add_index :orders, :customer_phone
    add_index :orders, :customer_email
    add_index :orders, :order_date
    add_index :orders, :shipped_date
    add_index :orders, :delivered_date
  end
end