class CreateInventoryLots < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_lots do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.string :lot_number, null: false
      t.integer :quantity_received, null: false
      t.integer :quantity_remaining, null: false
      t.decimal :unit_cost, precision: 10, scale: 4, null: false
      t.decimal :total_cost, precision: 10, scale: 2, null: false
      t.decimal :landed_cost_per_unit, precision: 10, scale: 4
      t.decimal :total_landed_cost, precision: 10, scale: 2
      t.date :received_date, null: false
      t.date :expiry_date
      t.string :supplier_name
      t.string :purchase_order_number
      t.string :status, default: 'active'
      t.jsonb :cost_breakdown, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :inventory_lots, :product_variant_id
    add_index :inventory_lots, :lot_number, unique: true
    add_index :inventory_lots, :received_date
    add_index :inventory_lots, :expiry_date
    add_index :inventory_lots, :status
    add_index :inventory_lots, :supplier_name
    add_index :inventory_lots, :purchase_order_number
  end
end