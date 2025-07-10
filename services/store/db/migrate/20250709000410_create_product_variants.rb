class CreateProductVariants < ActiveRecord::Migration[7.2]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku, null: false
      t.string :barcode
      t.string :name
      t.decimal :price, precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2
      t.decimal :weight, precision: 8, scale: 3
      t.string :weight_unit, default: 'kg'
      t.integer :position, default: 1
      t.boolean :active, default: true
      t.boolean :requires_shipping, default: true
      t.boolean :track_inventory, default: true
      t.integer :inventory_quantity, default: 0
      t.string :inventory_policy, default: 'deny'
      t.string :fulfillment_service, default: 'manual'
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.jsonb :option_values, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :product_variants, :product_id, if_not_exists: true
    add_index :product_variants, :sku, unique: true, if_not_exists: true
    add_index :product_variants, :barcode, unique: true, if_not_exists: true
    add_index :product_variants, :active, if_not_exists: true
    add_index :product_variants, :option_values, using: :gin, if_not_exists: true
  end
end