class AddReplyToMessageIdToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :reply_to_message_id, :bigint
    add_index :messages, :reply_to_message_id
    add_foreign_key :messages, :messages, column: :reply_to_message_id
  end
end
