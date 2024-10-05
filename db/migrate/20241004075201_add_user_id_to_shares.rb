class AddUserIdToShares < ActiveRecord::Migration[7.1]
  def change
    add_reference :shares, :user, null: false
  end
end
