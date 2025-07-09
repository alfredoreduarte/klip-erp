class CreateWahaEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :waha_events do |t|
      t.string :session_name, comment: "WAHA session name"
      t.string :event_name, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :waha_events, :created_at
  end
end