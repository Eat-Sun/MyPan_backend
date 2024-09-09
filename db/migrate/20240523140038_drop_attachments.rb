class DropAttachments < ActiveRecord::Migration[7.1]
  def change
    drop_table :attachments
  end
end
