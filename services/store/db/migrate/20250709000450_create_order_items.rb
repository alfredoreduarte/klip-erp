class CreateOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.decimal :unit_cost, precision: 10, scale: 4
      t.decimal :total_cost, precision: 10, scale: 2
      t.string :fulfillment_status, default: 'pending'
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :order_items, :order_id, if_not_exists: true
    add_index :order_items, :product_variant_id, if_not_exists: true
    add_index :order_items, :fulfillment_status, if_not_exists: true
  end
end