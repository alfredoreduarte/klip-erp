class AddNotNullToJsonbColumns < ActiveRecord::Migration[7.2]
  def change
    jsonb_columns_with_hash_default = {
      products: [:custom_attributes, :metadata],
      product_variants: [:option_values, :metadata],
      inventory_lots: [:cost_breakdown, :metadata],
      packaging_materials: [:metadata],
      orders: [:metadata],
      order_items: [:metadata],
      carts: [:metadata],
      cart_items: [:metadata],
      payments: [:processor_response, :metadata],
      cash_register_sessions: [:metadata],
      sourcing_orders: [:cost_breakdown, :metadata],
      sourcing_order_items: [:metadata],
      marketing_campaigns: [:performance_metrics, :metadata],
      order_attributions: [:metadata]
    }

    jsonb_columns_with_array_default = {
      shipments: [:tracking_events]
    }

    # Apply NOT NULL for columns with `{}` default
    jsonb_columns_with_hash_default.each do |table, columns|
      columns.each do |column|
        change_column_default table, column, from: nil, to: {}
        execute "UPDATE #{table} SET #{column} = '{}' WHERE #{column} IS NULL;"
        change_column_null table, column, false
      end
    end

    # Apply NOT NULL for columns with `[]` default
    jsonb_columns_with_array_default.each do |table, columns|
      columns.each do |column|
        change_column_default table, column, from: nil, to: []
        execute "UPDATE #{table} SET #{column} = '[]' WHERE #{column} IS NULL;"
        change_column_null table, column, false
      end
    end
  end
end