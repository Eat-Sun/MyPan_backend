class Attachment < ApplicationRecord
	belongs_to :folder
  belongs_to :file_monitor, optional: true
  has_and_belongs_to_many :shares

  after_create :plus_file_monitor
  after_destroy :minus_file_monitor

	scope :pictures, -> { where(:file_type => 'picture')}
	scope :words, -> { where(:file_type => 'word')}
	scope :vidios, -> { where(:file_type => 'video')}
	scope :audios, -> { where(:file_type => 'audio')}
	scope :undefined, -> { where(:file_type => 'undefined')}

	module Initial
		BucketName = { My_Pan: 'My-Pan'}
	end

	#上传文件时更新数据库
	def self.update_of_upload_for_database user_id, parent_folder, file_size, file_name, b2_key, file_type
    retries = 0
    begin
      attachment = nil

      transaction do
        result = User.update_used_space user_id, file_size

        attachment = parent_folder.attachments.create!(file_name: file_name, file_type: file_type, b2_key: b2_key, byte_size: file_size) if result
      end

      if attachment
        return {
          id: attachment.id,
          type: attachment.file_type,
          name: attachment.file_name,
          b2_key: attachment.b2_key,
          size: attachment.byte_size
        }
      end
      return false
    rescue => e
      if retries < 3
        retries += 1
        sleep 1

        retry
      else
        Attachment.models_logger.error e.message

        return e
      end
    end
	end

  #下载文件
  def self.download_from_blackblaze b2_keys
    begin
      presigned_urls = []

      b2_keys.each do |b2_key|
        obj = S3_Resource.bucket(Conf::BUCKETNAME[:My_Pan]).object(b2_key)
        if obj.exists?
          presigned_url = obj.presigned_url(:get, expires_in: 172800)
          presigned_urls << presigned_url
        end
      end

      presigned_urls.any? ? presigned_urls : false
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end

  end

  #删除文件
  def self.update_of_destroy_for_database user, data
    folder_items_id = []
    attachment_items_id = []
    classify data, folder_items_id, attachment_items_id
    # p "folder_items_id:", folder_items_id
    # p "attachment_items_id:", attachment_items_id
    begin
      if folder_items_id.any? || attachment_items_id.any?

        RemoveAttachmentAndFolderJob.perform_later(folder_items_id, attachment_items_id)
      end

      return true
    rescue => e
      Attachment.models_logger.error e.message

      return e
    end

  end

	# 获取文件
  def self.get_filelist_from_backblaze user
    arranged_data = Folder.includes(:attachments).find_by(user: user, folder_name: "root").subtree.arrange

    form_data = process_data arranged_data
    # p form_data
    return form_data
  end

  # 移动文件
  def self.move_attachments user, attachment_items_id, target_folder
    return true if attachment_items_id.blank?

    attachments = Attachment.where(id: attachment_items_id)

    begin
      if attachments.present? and target_folder.present?
          attachments.update_all(folder_id: target_folder.id)

        return true
      else

        return false
      end
    rescue => e
      Attachment.models_logger.error e.message
      p "出错：", e.message
      raise e
    end
  end

  private
    def plus_file_monitor
      begin
        file_monitor = FileMonitor.find_by(b2_key: self.b2_key)

        if file_monitor
          file_monitor.lock!

          file_monitor.increment!(:owner_count)
        else

          FileMonitor.create!(owner_count: 1, attachments: [self])
        end
      rescue => e
        Attachment.models_logger.error e.message

        return e
      end
    end

    def minus_file_monitor
      begin
        FileMonitor.where(b2_key: self.b2_key).update_counters(owner_count: -1)

        FileMonitor.need_to_destroy
      rescue => e
        Attachment.models_logger.error e.message

        return e
      end

    end

    def self.process_data arranged_data
      arranged_data.map do |folder, children|

        {
          id: folder.id,
          type: "folder",
          name: folder.folder_name,
          children: process_data(children) + attached_files_info(folder.attachments)
        }

      end
    end

    def self.attached_files_info(filelist)
      filelist.map do |file|
        {
          id: file.id,
          type: file.file_type,
          name: file.file_name,
          b2_key: file.b2_key,
          size: file.byte_size
        }
      end
    end

    def self.classify data, folder_items_id, attachment_items_id
      data.each do |item|
        if item[:type] == 'folder'
          folder_items_id << item["id"]
          classify item["children"], folder_items_id, attachment_items_id
        else
          attachment_items_id << item["id"]
        end
      end
    end
end
