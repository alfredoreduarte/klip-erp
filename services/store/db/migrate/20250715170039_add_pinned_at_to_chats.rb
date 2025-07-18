class AddPinnedAtToChats < ActiveRecord::Migration[7.2]
  def change
    add_column :chats, :pinned_at, :datetime
    add_index :chats, :pinned_at
  end
end
