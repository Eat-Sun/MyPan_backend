class UpdateTableAttachmentMonitor < ActiveRecord::Migration[7.1]
  def change
    drop_table :attachment_monitors
    create_table :file_monitors do |t|
      t.belongs_to :attachment
      t.belongs_to :folder
      t.integer :owner_count, default: 0
      t.timestamps
    end
  end
end
