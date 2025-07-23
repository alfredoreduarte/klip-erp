class CreateMediaFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :media_files do |t|
      t.string :filename
      t.string :mimetype
      t.references :message, null: false, foreign_key: true

      t.timestamps
    end
  end
end
