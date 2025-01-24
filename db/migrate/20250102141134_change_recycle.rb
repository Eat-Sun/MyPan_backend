class ChangeRecycle < ActiveRecord::Migration[7.1]
  def change
    remove_column :recycle_bins, :name
    remove_column :recycle_bins, :b2_key
    remove_column :recycle_bins, :byte_size
    remove_column :recycle_bins, :numbering
    add_column :recycle_bins, :is_top, :boolean
    #Ex:- add_column("admin_users", "username", :string, :limit =>25, :after => "email")
  end
end
