class FolderShare < ApplicationRecord
  self.table_name = 'folders_shares'
  belongs_to :folder
  belongs_to :share
end
