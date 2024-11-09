class AddTopColunmToMiddleTable < ActiveRecord::Migration[7.1]
  def change
    add_column :folders_shares, :top, :boolean
    add_column :attachments_shares, :top, :boolean
    #Ex:- add_column("admin_users", "username", :string, :limit =>25, :after => "email")
  end
end
