class RenameTypeInAttachment < ActiveRecord::Migration[7.1]
  def change
    rename_column :attachments, :type, :file_type
  end
end
