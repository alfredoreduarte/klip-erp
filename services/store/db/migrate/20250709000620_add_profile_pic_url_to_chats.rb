class AddProfilePicUrlToChats < ActiveRecord::Migration[7.2]
  def change
    add_column :chats, :profile_pic_url, :string
  end
end