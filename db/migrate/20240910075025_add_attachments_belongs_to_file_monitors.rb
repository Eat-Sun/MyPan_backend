class AddAttachmentsBelongsToFileMonitors < ActiveRecord::Migration[7.1]
  def up
    add_column :attachments, :file_monitor_id, :integer
    remove_column :file_monitors, :attachment_id

    add_index :attachments, :file_monitor_id
  end

  def down
    remove_column :attachments, :file_monitor_id
    add_column :file_monitors, :attachment_id, :integer

    remove_index :attachments, :file_monitor_id
  end
end
