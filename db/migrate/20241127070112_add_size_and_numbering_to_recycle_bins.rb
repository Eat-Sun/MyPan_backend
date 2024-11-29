class AddSizeAndNumberingToRecycleBins < ActiveRecord::Migration[7.1]
  def change
    add_column :recycle_bins, :byte_size, :string
    add_column :recycle_bins, :numbering, :string
  end
end
