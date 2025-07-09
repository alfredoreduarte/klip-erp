class CreateSourcingOrders < ActiveRecord::Migration[7.2]
  def change
    create_table :sourcing_orders do |t|
      t.string :po_number, null: false
      t.string :supplier_name, null: false
      t.string :supplier_contact
      t.string :supplier_email
      t.string :status, default: 'draft'
      t.decimal :subtotal, precision: 10, scale: 2, default: 0
      t.decimal :shipping_cost, precision: 10, scale: 2, default: 0
      t.decimal :customs_duty, precision: 10, scale: 2, default: 0
      t.decimal :marketplace_fees, precision: 10, scale: 2, default: 0
      t.decimal :handling_fees, precision: 10, scale: 2, default: 0
      t.decimal :other_costs, precision: 10, scale: 2, default: 0
      t.decimal :total_cost, precision: 10, scale: 2, default: 0
      t.string :currency, default: 'USD'
      t.date :order_date
      t.date :expected_delivery_date
      t.date :actual_delivery_date
      t.text :terms_and_conditions
      t.text :notes
      t.jsonb :cost_breakdown, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :sourcing_orders, :po_number, unique: true
    add_index :sourcing_orders, :supplier_name
    add_index :sourcing_orders, :status
    add_index :sourcing_orders, :order_date
    add_index :sourcing_orders, :expected_delivery_date
    add_index :sourcing_orders, :actual_delivery_date
  end
end