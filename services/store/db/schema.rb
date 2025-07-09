# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_09_000200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "chats", force: :cascade do |t|
    t.string "wa_id", null: false, comment: "WhatsApp chat JID (phone@c.us)"
    t.string "name", comment: "Contact or group name if available"
    t.datetime "last_message_at", comment: "Timestamp of last message processed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["wa_id"], name: "index_chats_on_wa_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "chat_id", null: false
    t.string "wa_message_id", null: false, comment: "WhatsApp message ID"
    t.integer "direction", default: 0, null: false, comment: "0=incoming,1=outgoing"
    t.string "message_type", default: "text", null: false, comment: "WhatsApp message type (text,image,document,...)"
    t.text "body"
    t.jsonb "payload", default: {}, null: false, comment: "Raw WAHA payload"
    t.datetime "sent_at", comment: "Original timestamp from WhatsApp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["wa_message_id"], name: "index_messages_on_wa_message_id", unique: true
  end

  add_foreign_key "messages", "chats"
end
