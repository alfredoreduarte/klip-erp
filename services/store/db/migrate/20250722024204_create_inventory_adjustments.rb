class CreateInventoryAdjustments < ActiveRecord::Migration[7.2]
  def change
    create_table :inventory_adjustments do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.string :adjustment_type, null: false, limit: 50
      t.integer :quantity, null: false
      t.string :reason, limit: 100
      t.text :notes
      t.string :reference_number, limit: 50
      t.integer :user_id
      t.decimal :cost_impact, precision: 10, scale: 2
      t.integer :quantity_before, null: false
      t.integer :quantity_after, null: false
      t.jsonb :metadata, default: {}
      t.boolean :approved, default: false
      t.datetime :approved_at
      t.integer :approved_by_user_id

      t.timestamps
    end

    add_index :inventory_adjustments, :adjustment_type
    add_index :inventory_adjustments, :reference_number
    add_index :inventory_adjustments, :user_id
    add_index :inventory_adjustments, :approved
    add_index :inventory_adjustments, :created_at
    add_index :inventory_adjustments, [:product_variant_id, :created_at]
    add_index :inventory_adjustments, :metadata, using: :gin
  end
end
