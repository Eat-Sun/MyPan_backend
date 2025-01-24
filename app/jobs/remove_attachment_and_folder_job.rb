class RemoveAttachmentAndFolderJob < ApplicationJob
  queue_as :file_operation

  def perform(folder_ids, attachment_ids)
    if folder_ids.present?

      Folder.delete_folder folder_ids
    end
    if attachment_ids.present?
      attachments = Attachment.where(id: attachment_ids)
      b2_keys = nil

      begin
        ActiveRecord::Base.transaction do
          attachments.destroy_all
          b2_keys = FileMonitor.need_to_destroy
        end

        S3_Resource.bucket(Conf::BUCKETNAME[:My_Pan]).delete_objects({
          delete: {
            objects: b2_keys
          }
        })
      rescue => e
        p "出现错误：", e
      end
    end
  end
end
