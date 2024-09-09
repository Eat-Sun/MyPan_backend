class CreateAttachmentMonitors < ActiveRecord::Migration[7.1]
  def change
    create_table :attachment_monitors do |t|
      t.belongs_to :attachment
      t.integer :owner_count, default: 0
      t.timestamps
    end

  end
end
