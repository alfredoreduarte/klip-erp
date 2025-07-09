class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.references :chat, null: false, foreign_key: true
      t.string :wa_message_id, null: false, index: { unique: true }, comment: "WhatsApp message ID"
      t.integer :direction, null: false, default: 0, comment: "0=incoming,1=outgoing"
      t.string :message_type, null: false, default: "text", comment: "WhatsApp message type (text,image,document,...)"
      t.text :body
      t.jsonb :payload, null: false, default: {}, comment: "Raw WAHA payload"
      t.datetime :sent_at, comment: "Original timestamp from WhatsApp"

      t.timestamps
    end
  end
end