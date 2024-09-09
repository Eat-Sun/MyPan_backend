class RemoveColumnOwnerCountFromAttachments < ActiveRecord::Migration[7.1]
  def change
    remove_column :attachments, :owner_num, :integer
    add_column :shares, :owner_num, :integer
  end
end
