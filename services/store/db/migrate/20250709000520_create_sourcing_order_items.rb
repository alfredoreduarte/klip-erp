class CreateSourcingOrderItems < ActiveRecord::Migration[7.2]
  def change
    create_table :sourcing_order_items do |t|
      t.references :sourcing_order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity_ordered, null: false
      t.integer :quantity_received, default: 0
      t.decimal :unit_cost, precision: 10, scale: 4, null: false
      t.decimal :total_cost, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending'
      t.date :expected_date
      t.date :received_date
      t.text :notes
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :sourcing_order_items, :sourcing_order_id, if_not_exists: true
    add_index :sourcing_order_items, :product_variant_id, if_not_exists: true
    add_index :sourcing_order_items, :status
    add_index :sourcing_order_items, :expected_date
    add_index :sourcing_order_items, :received_date
  end
end