class SorceryCore < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :username
      t.decimal :total_space, precision: 10, scale: 2
      t.decimal :used_space, precision: 10, scale: 2
      t.string :status, :default => 'active'
      t.string :email,            null: false, index: { unique: true }
      t.string :crypted_password
      t.string :salt

      t.timestamps                null: false
    end
  end
end
