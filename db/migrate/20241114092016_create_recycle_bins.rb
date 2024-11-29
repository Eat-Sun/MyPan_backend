class CreateRecycleBins < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :in_bins, :boolean
    add_column :folders, :in_bins, :boolean

    add_index :attachments, :in_bins
    add_index :folders, :in_bins
  end
end
