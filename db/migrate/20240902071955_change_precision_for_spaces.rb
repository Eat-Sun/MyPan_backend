class ChangePrecisionForSpaces < ActiveRecord::Migration[7.1]
  def change
    # 删除旧列
    remove_column :users, :total_space
    remove_column :users, :used_space

    # 添加新列，使用新的精度和小数位数
    add_column :users, :total_space, :decimal, precision: 12
    add_column :users, :used_space, :decimal, precision: 12

  end
end
