class AddFoldersColumnNumbering < ActiveRecord::Migration[7.1]
  def change
    add_column :folders, :numbering, :string
    add_index :folders, :numbering
    #Ex:- add_index("admin_users", "username")
  end
end
