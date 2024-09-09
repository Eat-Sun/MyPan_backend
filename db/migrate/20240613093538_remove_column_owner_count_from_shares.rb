class RemoveColumnOwnerCountFromShares < ActiveRecord::Migration[7.1]
  def change
    remove_column :shares, :owner_num, :integer
  end
end
