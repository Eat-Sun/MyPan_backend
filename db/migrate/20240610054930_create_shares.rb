class CreateShares < ActiveRecord::Migration[7.1]
  def change
    create_table :shares do |t|
      t.belongs_to :attachment
      t.string :link
      t.string :varify
      t.datetime :expires_at
      t.timestamps
    end
  end
end
