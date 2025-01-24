class RecycleBin < ApplicationRecord
  # self.inheritance_column = :_type_disabled
  belongs_to :user

  #添加到回收站
  def self.add_to_bins user_id, opt
    begin
      user = User.find user_id
      result = user.recycle_bin.insert_all!(opt, returning: [:id, :mix_id, :type, :is_top])

      return result.as_json
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end
  end

  #删除记录
  def self.remove bin_ids: nil
    RecycleBin.where(id: bin_ids).delete_all
  end
  #恢复文件
  # def self.restore user_id, folder_ids = nil, attachment_ids = nil, bin_ids = nil
  #   now = Time.current
  #   root = User.get_root user_id
  #   begin
  #     result = false

  #     transaction do
  #       Folder.where(id: folder_ids).update_all(in_bins: false, updated_at: now)
  #       Attachment.where(id: attachment_ids).update_all(in_bins: false, ancestry: root.numbering, updated_at: now)
  #       result = RecycleBin.where(id: bin_ids).delete_all
  #     end

  #     return result
  #   rescue => e
  #     Attachment.models_logger.error e.message

  #     return e
  #   end
  # end

  #获取回收站文件
  # def self.get_recycled user_id
  #   result = RecycleBin.select(:id, :mix_id, :type, :name, :b2_key).where(user_id: user_id)

  #   return result
  # end

end
