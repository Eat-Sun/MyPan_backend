class AddColumnTypeToAttachment < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :type, :string, default: 'undefined'
    # options：default:（指定列的默认值）, null:（允许或禁止 NULL 值）, limit:（设置字符串或文本列的最大长度）, precision:（设置十进制列的精度）, scale:（设置十进制列的小数位数）, first:（将列添加到表的开头）, after:（将列添加到另一列之后）
  end
end
