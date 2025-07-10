class AddWahaSessionRefToChats < ActiveRecord::Migration[7.1]
  def change
    add_reference :chats, :waha_session, foreign_key: true, null: true
  end
end