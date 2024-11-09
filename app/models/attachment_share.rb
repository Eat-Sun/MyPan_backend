class AttachmentShare < ApplicationRecord
  self.table_name = 'attachments_shares'
  belongs_to :attachment
  belongs_to :share
end
