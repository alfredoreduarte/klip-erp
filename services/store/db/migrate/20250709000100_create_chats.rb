class CreateChats < ActiveRecord::Migration[7.1]
  def change
    create_table :chats do |t|
      t.string :wa_id, null: false, index: { unique: true }, comment: "WhatsApp chat JID (phone@c.us)"
      t.string :name, comment: "Contact or group name if available"
      t.datetime :last_message_at, comment: "Timestamp of last message processed"

      t.timestamps
    end
  end
end