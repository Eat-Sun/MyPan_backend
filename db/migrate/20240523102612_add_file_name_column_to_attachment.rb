class AddFileNameColumnToAttachment < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :file_name, :string
  end
end
