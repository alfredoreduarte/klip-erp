class CreateCarts < ActiveRecord::Migration[7.2]
  def change
    create_table :carts do |t|
      t.references :chat, null: true, foreign_key: true
      t.string :session_id
      t.string :customer_name
      t.string :customer_phone
      t.string :customer_email
      t.string :status, default: 'active'
      t.string :channel, null: false # 'whatsapp', 'web', 'pos'
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :tax_amount, precision: 10, scale: 2, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.string :currency, default: 'USD'
      t.text :shipping_address
      t.text :billing_address
      t.text :notes
      t.datetime :expires_at
      t.datetime :last_activity_at
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :carts, :chat_id
    add_index :carts, :session_id
    add_index :carts, :customer_phone
    add_index :carts, :status
    add_index :carts, :channel
    add_index :carts, :expires_at
    add_index :carts, :last_activity_at
  end
end