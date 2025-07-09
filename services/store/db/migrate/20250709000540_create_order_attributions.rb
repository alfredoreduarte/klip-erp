class CreateOrderAttributions < ActiveRecord::Migration[7.2]
  def change
    create_table :order_attributions do |t|
      t.references :order, null: false, foreign_key: true
      t.references :marketing_campaign, null: false, foreign_key: true
      t.string :attribution_type, null: false # 'first_click', 'last_click', 'linear', 'time_decay'
      t.decimal :attribution_weight, precision: 5, scale: 4, default: 1.0
      t.decimal :attributed_revenue, precision: 10, scale: 2
      t.decimal :attributed_cost, precision: 10, scale: 2
      t.datetime :click_timestamp
      t.datetime :conversion_timestamp
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.string :utm_term
      t.string :utm_content
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :order_attributions, :order_id
    add_index :order_attributions, :marketing_campaign_id
    add_index :order_attributions, :attribution_type
    add_index :order_attributions, :click_timestamp
    add_index :order_attributions, :conversion_timestamp
    add_index :order_attributions, :utm_source
    add_index :order_attributions, :utm_campaign
  end
end