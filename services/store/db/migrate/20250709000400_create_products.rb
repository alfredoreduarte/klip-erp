class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :brand
      t.decimal :base_price, precision: 10, scale: 2
      t.decimal :cost_price, precision: 10, scale: 2
      t.string :status, default: 'active'
      t.boolean :track_inventory, default: true
      t.decimal :weight, precision: 8, scale: 3
      t.string :weight_unit, default: 'kg'
      t.decimal :length, precision: 8, scale: 3
      t.decimal :width, precision: 8, scale: 3
      t.decimal :height, precision: 8, scale: 3
      t.string :dimension_unit, default: 'cm'
      t.string :tax_category
      t.jsonb :attributes, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :products, :name
    add_index :products, :category
    add_index :products, :brand
    add_index :products, :status
    add_index :products, :attributes, using: :gin
  end
end