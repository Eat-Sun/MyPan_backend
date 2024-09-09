class AddColumnB2KeyToAttachment < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :b2_key, :string
    add_column :attachments, :byte_size, :string
  end
end
