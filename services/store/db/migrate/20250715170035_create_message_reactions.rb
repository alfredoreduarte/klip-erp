class CreateMessageReactions < ActiveRecord::Migration[7.2]
  def change
    create_table :message_reactions do |t|
      t.references :message, null: false, foreign_key: true
      t.string :reaction, null: false
      t.string :user_wa_id, null: false, comment: "WhatsApp user ID who reacted"
      t.datetime :created_at, null: false
    end

    add_index :message_reactions, [:message_id, :user_wa_id], unique: true
    add_index :message_reactions, :user_wa_id
  end
end
