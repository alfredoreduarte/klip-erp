class CreateShipments < ActiveRecord::Migration[7.2]
  def change
    create_table :shipments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :tracking_number, null: false
      t.string :carrier_name
      t.string :carrier_service
      t.string :status, default: 'pending'
      t.decimal :cost, precision: 10, scale: 2
      t.decimal :weight, precision: 8, scale: 3
      t.string :weight_unit, default: 'kg'
      t.text :origin_address
      t.text :destination_address
      t.datetime :shipped_at
      t.datetime :delivered_at
      t.datetime :estimated_delivery
      t.text :delivery_instructions
      t.string :proof_of_delivery
      t.text :notes
      t.jsonb :tracking_events, default: []
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :shipments, :order_id
    add_index :shipments, :tracking_number, unique: true
    add_index :shipments, :carrier_name
    add_index :shipments, :status
    add_index :shipments, :shipped_at
    add_index :shipments, :delivered_at
    add_index :shipments, :estimated_delivery
  end
end