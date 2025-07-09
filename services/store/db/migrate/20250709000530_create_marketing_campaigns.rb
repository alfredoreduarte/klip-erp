class CreateMarketingCampaigns < ActiveRecord::Migration[7.2]
  def change
    create_table :marketing_campaigns do |t|
      t.string :name, null: false
      t.string :platform, null: false # 'facebook', 'instagram', 'google', etc.
      t.string :campaign_id, null: false
      t.string :campaign_type
      t.string :status, default: 'active'
      t.decimal :budget, precision: 10, scale: 2
      t.decimal :spent, precision: 10, scale: 2, default: 0
      t.decimal :cost_per_click, precision: 10, scale: 4
      t.decimal :cost_per_conversion, precision: 10, scale: 4
      t.integer :impressions, default: 0
      t.integer :clicks, default: 0
      t.integer :conversions, default: 0
      t.date :start_date
      t.date :end_date
      t.text :targeting_criteria
      t.text :creative_content
      t.jsonb :performance_metrics, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :marketing_campaigns, :name
    add_index :marketing_campaigns, :platform
    add_index :marketing_campaigns, :campaign_id, unique: true
    add_index :marketing_campaigns, :status
    add_index :marketing_campaigns, :start_date
    add_index :marketing_campaigns, :end_date
  end
end