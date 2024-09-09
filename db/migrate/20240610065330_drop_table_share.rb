class DropTableShare < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments_shares, id: false do |t|
      t.belongs_to :attachment
      t.belongs_to :share
    end

    remove_column :shares, :attachment_id, :integer
  end
end
