class CreateCartItems < ActiveRecord::Migration[7.2]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :cart_items, :cart_id, if_not_exists: true
    add_index :cart_items, :product_variant_id, if_not_exists: true
    add_index :cart_items, [:cart_id, :product_variant_id], unique: true, if_not_exists: true
  end
end