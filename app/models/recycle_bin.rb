class RecycleBin < ApplicationRecord
  self.inheritance_column = :_type_disabled
  belongs_to :user

  #添加到回收站
  def self.add_to_bins user, folder_ids = nil, attachment_ids = nil, mixed = nil
    now = Time.current

    begin
      result = true

      transaction do
        Attachment.where(id: attachment_ids).update_all(in_bins: true, updated_at: now)
        Folder.where(id: folder_ids).update_all(in_bins: true, updated_at: now)
        user.recycle_bin.insert_all!(mixed)
      end

      return result
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end
  end

  #恢复文件
  def self.restore folder_ids = nil, attachment_ids = nil, bin_ids = nil
    now = Time.current

    begin
      result = false

      transaction do
        Folder.where(id: folder_ids).update_all(in_bins: false, updated_at: now)
        Attachment.where(id: attachment_ids).update_all(in_bins: false, updated_at: now)
        result = RecycleBin.where(id: bin_ids).delete_all
      end

      return result
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end
  end

  #获取回收站文件
  def self.get_recycled user_id
    result = RecycleBin.select(:id, :mix_id, :type, :name, :b2_key).where(user_id: user_id)

    return result
  end

  #彻底删除文件
  def self.remove folder_ids = nil, attachment_ids = nil, bin_ids = nil
    begin
      if folder_ids.any? || attachment_ids.any?
        RemoveAttachmentAndFolderJob.perform_later(folder_ids, attachment_ids)
        RecycleBin.where(id: bin_ids).delete_all

        return true
      end

      return false
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end
  end
end
