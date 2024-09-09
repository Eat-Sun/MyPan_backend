class RecreateAttachment < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments do |t|
      t.belongs_to :folder
      t.string :file_name, null: false
      t.timestamps
    end
  end
end
