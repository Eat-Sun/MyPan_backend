class ChangeFolderIdToB2Key < ActiveRecord::Migration[7.1]
  def change
    remove_column :file_monitors, :folder_id
    add_column :file_monitors, :b2_key, :string
  end
end
