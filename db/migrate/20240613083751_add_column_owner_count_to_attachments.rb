class AddColumnOwnerCountToAttachments < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :owner_num, :integer
  end
end
