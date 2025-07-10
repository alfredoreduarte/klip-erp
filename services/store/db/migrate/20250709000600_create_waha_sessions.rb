class CreateWahaSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :waha_sessions do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "inactive"
      t.datetime :last_qr_generated_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :waha_sessions, :name, unique: true
    add_index :waha_sessions, :status
  end
end