class ChangeAncestryInFolders < ActiveRecord::Migration[7.1]
  def change
    change_column_null :folders, :ancestry, true
  end
end
