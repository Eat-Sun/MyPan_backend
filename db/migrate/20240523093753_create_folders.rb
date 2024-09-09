class CreateFolders < ActiveRecord::Migration[7.1]
  def change
    create_table :folders do |t|
      t.belongs_to :user
      t.string :folder_name
      t.string "ancestry", null: false
      t.index "ancestry"
      t.timestamps
    end
  end
end
