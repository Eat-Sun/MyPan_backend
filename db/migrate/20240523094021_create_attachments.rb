class CreateAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments do |t|
      t.belongs_to :folder
      t.timestamps
    end
  end
end
