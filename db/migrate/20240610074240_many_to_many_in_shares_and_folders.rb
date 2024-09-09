class ManyToManyInSharesAndFolders < ActiveRecord::Migration[7.1]
  def change
    create_table :folders_shares, id: false do |t|
      t.belongs_to :folder
      t.belongs_to :share
    end

    add_index :shares, :link
  end
end
