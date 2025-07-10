class CreatePackagingMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :packaging_materials do |t|
      t.string :name, null: false
      t.text :description
      t.string :sku
      t.string :category
      t.string :unit_type, null: false # 'piece', 'meter', 'kg', etc.
      t.decimal :unit_cost, precision: 10, scale: 4, null: false
      t.integer :quantity_on_hand, default: 0
      t.integer :reorder_point, default: 0
      t.decimal :weight_per_unit, precision: 8, scale: 3
      t.string :weight_unit, default: 'kg'
      t.decimal :length, precision: 8, scale: 3
      t.decimal :width, precision: 8, scale: 3
      t.decimal :height, precision: 8, scale: 3
      t.string :dimension_unit, default: 'cm'
      t.string :supplier_name
      t.string :supplier_sku
      t.boolean :active, default: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :packaging_materials, :name
    add_index :packaging_materials, :sku, unique: true
    add_index :packaging_materials, :category
    add_index :packaging_materials, :active
    add_index :packaging_materials, :supplier_name
  end
end