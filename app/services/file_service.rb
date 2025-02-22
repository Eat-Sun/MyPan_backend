module FileService
  module RecycleService
    #添加到回收站
    def self.add_to_bins user_id: nil, folder_ids: nil, attachment_ids: nil, opt: nil
      ActiveRecord::Base.transaction do
        Attachment.where(id: attachment_ids).update_all(in_bins: true)
        Folder.where(id: folder_ids).update_all(in_bins: true)
        RecycleBin.add_to_bins(user_id, opt)
      end
    end
    #从回收站恢复
    def self.restore folders: nil, attachments: nil, bin_ids: nil
      ActiveRecord::Base.transaction do
        Attachment.restore_from_bin attachments: attachments
        Folder.restore_from_bin folders: folders
        RecycleBin.remove bin_ids: bin_ids
      end
    end
    #获取用户回收的文件
    def self.get_recycled user_id: nil
      attachments = Attachment.get_recycled user_id
      folders = Folder.get_recycled user_id

      return {
        folders: folders,
        attachments: attachments
      }
    end
    #从回收站永久删除文件
    def self.remove user: nil, free_space: nil, folder_ids: nil, attachment_ids: nil, bin_ids: nil
      begin
        if folder_ids.any? || attachment_ids.any?
          p "result: #{user.total_space - free_space.to_i}"
          ActiveRecord::Base.transaction do
            user.update_attribute!(:used_space, user.total_space - free_space.to_i)
            RecycleBin.remove bin_ids: bin_ids
          end

          RemoveAttachmentAndFolderJob.perform_later(folder_ids, attachment_ids)
        end
      rescue => e
        Attachment.models_logger.error e.message

        return e
      end
    end
  end
  #获取用户的活跃文件
  def self.get_filelist_from_db user, in_bins: false
    begin
      folders = Folder.get_active_folders user: user
      folder_ids = folders.map { |folder| folder[:id] }
      attachments = Attachment.get_active_attachments folder_ids: folder_ids

      return {
        folders: folders,
        attachments: attachments
      }
    rescue => e
      return e
    end
  end
end
