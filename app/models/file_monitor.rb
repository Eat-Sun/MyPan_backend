class FileMonitor < ApplicationRecord
  has_many :attachments
  validates :owner_count, presence: { message: '所有者数量不能为空' }
  validate :attachment_must_be_present

  def self.need_to_destroy
    need_delete_file_monitors = FileMonitor.where(owner_count: 0)
    b2_keys = need_delete_file_monitors.map { |file_monitor| { key: file_monitor.b2_key } }

    need_delete_file_monitors.delete_all

    b2_keys
  end

  private

  def attachment_must_be_present
    return unless attachments.empty?

    errors.add(:base, '必须至少选择一个 attachment')
  end
end
