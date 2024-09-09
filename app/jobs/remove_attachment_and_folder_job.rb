class RemoveAttachmentAndFolderJob < ApplicationJob
  queue_as :file_operation

  def perform(folder_items_id, attachment_items_id)
    if folder_items_id.present?

      Folder.delete_folder folder_items_id
    end
    if attachment_items_id.present?
      attachments = Attachment.where(id: attachment_items_id)
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
