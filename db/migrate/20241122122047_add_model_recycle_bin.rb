class AddModelRecycleBin < ActiveRecord::Migration[7.1]
  def change
    create_table :recycle_bins do |t|
      t.belongs_to :user
      t.integer :mix_id
      t.string :type
      t.string :name
      t.string :b2_key
      t.timestamps
    end

    add_index :recycle_bins, [:mix_id, :b2_key]
    #Ex:- add_index("admin_users", "username")
  end
end
