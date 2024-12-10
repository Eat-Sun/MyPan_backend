class ChangeTypeB2keyOnFilemonitor < ActiveRecord::Migration[7.1]
  def change
    add_index :file_monitors, :b2_key, :unique => true
    #Ex:- add_index("admin_users", "username")
  end
end
