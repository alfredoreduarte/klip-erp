class AddProfilePicUrlToWahaSessions < ActiveRecord::Migration[7.2]
  def change
    add_column :waha_sessions, :profile_pic_url, :string
  end
end
