class AddPinnedAtToMessages < ActiveRecord::Migration[7.2]
  def change
    add_column :messages, :pinned_at, :datetime
  end
end
