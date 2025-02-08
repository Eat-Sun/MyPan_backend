class Attachment < ApplicationRecord
	belongs_to :folder
  belongs_to :file_monitor, optional: true
  has_many :attachments_shares, class_name: "AttachmentShare", dependent: :delete_all
  has_many :shares, through: :attachments_shares

  after_create :plus_file_monitor
  after_destroy :minus_file_monitor

	scope :pictures, -> { where(:file_type => 'picture')}
	scope :words, -> { where(:file_type => 'word')}
	scope :vidios, -> { where(:file_type => 'video')}
	scope :audios, -> { where(:file_type => 'audio')}
	scope :undefined, -> { where(:file_type => 'undefined')}

	scope :in_bins, -> { where(:in_bins => true).pluck(:id) }
	module Initial
		BucketName = { My_Pan: 'My-Pan'}
    Monitor = "monitor"
	end

	#上传文件时更新数据库
	def self.update_of_upload_for_database user_id, parent_folder, file_size, file_name, b2_key, file_type
    retries = 0
    begin
      attachment = nil
      transaction do
        result = User.update_used_space user_id, file_size
        attachment = parent_folder.attachments.create!(file_name: file_name, file_type: file_type, b2_key: b2_key, byte_size: file_size, in_bins: false) if result
      end

      if attachment
        return {
          id: attachment.id,
          folder_id: parent_folder.id,
          type: attachment.file_type,
          name: attachment.file_name,
          b2_key: attachment.b2_key,
          byte_size: attachment.byte_size
        }
      end
      return false
    rescue => e
      if retries < 2
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
  def self.download_from_blackblaze key_and_names
    begin
      presigned_urls = []

      key_and_names.each do |index, item|
        obj = S3_Resource.bucket(Conf::BUCKETNAME[:My_Pan]).object(item["key"])
        if obj.exists?
          presigned_url = obj.presigned_url(
            :get,
            expires_in: 172800, #两天后过期
            response_content_disposition: "attachment; filename=#{item["name"]}"
          )
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
  # def self.update_of_destroy_for_database folder_ids, attachement_ids
  #   begin
  #     if folder_ids.any? || attachement_ids.any?

  #       RemoveAttachmentAndFolderJob.perform_later(folder_ids, attachement_ids)
  #     end

  #     return true
  #   rescue => e
  #     Attachment.models_logger.error e.message

  #     return e
  #   end

  # end

	# 获取文件
  # def self.get_filelist_from_db user
  #   begin
  #     folders = Folder.where(user: user)
  #       .pluck("id, folder_name, numbering, ancestry")
  #       .map do |folder|
  #         {
  #           id: folder[0],
  #           type: 'folder',
  #           name: folder[1],
  #           numbering: folder[2],
  #           ancestry: folder[3],
  #           children: []
  #         }
  #       end
  #     attachments = Attachment.where(folder_id: folders.map { |folder| folder[:id] })
  #       .pluck("id, folder_id, file_type, file_name, b2_key, byte_size, file_monitor_id")
  #       .map do |attachment|
  #         {
  #           id: attachment[0],
  #           folder_id: attachment[1],
  #           type: attachment[2],
  #           name: attachment[3],
  #           b2_key: attachment[4],
  #           size: attachment[5]
  #         }
  #       end

  #     return [folders, attachments]
  #   rescue => e

  #     return e
  #   end
  # end

  # 移动文件
  def self.move_attachments attachment_items_id, target_folder
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
      return e
    end
  end

  #获取活跃文件
  def self.get_active_attachments folder_ids:
    attachments = Attachment.where(folder_id: folder_ids, in_bins: false)
      .pluck("id, folder_id, file_type, file_name, b2_key, byte_size")
      .map do |attachment|
        {
          id: attachment[0],
          folder_id: attachment[1],
          type: attachment[2],
          name: attachment[3],
          b2_key: attachment[4],
          byte_size: attachment[5]
        }
      end
  end

  #获取回收文件
  def self.get_recycled user_id
    attachments = Attachment.joins("INNER JOIN recycle_bins ON recycle_bins.mix_id = attachments.id").
      where("recycle_bins.user_id = ? and recycle_bins.type != 'folder'", user_id).
      where(in_bins: true).
      pluck("recycle_bins.id", :id, :folder_id, :file_type, :file_name, :b2_key, :byte_size, "recycle_bins.is_top")
      .map do |item|
        {
          id: item[0],
          mix_id: item[1],
          folder_id: item[2],
          type: item[3],
          name: item[4],
          b2_key: item[5],
          size: item[6],
          is_top: item[7]
        }
      end
  end

  #从回收站恢复
  def self.restore_from_bin attachments:
    ids = attachments[:ids]
    top_ids = attachments[:top_ids]
    parent_id = attachments[:parent_id]

    where(id: ids).update_all([
      "in_bins = false, folder_id = CASE WHEN id IN (?) THEN ? ELSE folder_id END",
      top_ids, parent_id
    ])
    # where(id: top_att_ids).update_all(in_bins: false, ancestry: ancestry)
  end

  private
    def plus_file_monitor
      if redis.sadd(Initial::Monitor, self.b2_key) != 1
        Rails.cache.increment(self.b2_key)
      else
        owner_count = FileMonitor.where(b2_key: self.b2_key).pluck(:owner_count)[0]
        # puts "开始处理：#{b2_key}，owner_count为:#{owner_count} \n"
        count = (owner_count || 0) + 1
        Rails.cache.increment(self.b2_key, count)
      end
    end

    def minus_file_monitor
      if redis.sadd(Initial::Monitor, self.b2_key) != 1
        Rails.cache.decrement(self.b2_key)
      else
        owner_count = FileMonitor.where(b2_key: self.b2_key).pluck(:owner_count)[0]
        # puts "开始处理：#{b2_key}，owner_count为:#{owner_count} \n"
        count = owner_count - 1
        Rails.cache.increment(self.b2_key, count)
      end
    end

    # def plus_file_monitor
    #   redis = Attachment.redis
    #   field = self.b2_key
    #   lock_field = "lock:#{field}"

    #   begin
    #     if redis.set(lock_field, 1, ex: 5, nx: true)
    #       begin
    #         redis.pipelined do
    #           value = JSON.parse(redis.hget(Initial::MonitorKey, field) || '[]')

    #           value << 1
    #           redis.hset(Initial::MonitorKey, field, value.to_json)
    #         end
    #       ensure
    #         redis.del(lock_field)
    #       end
    #     else
    #       raise "获取锁失败"
    #     end
    #   rescue => e
    #     if e.message == "获取锁失败"
    #       sleep(3)
    #       retry
    #     else
    #       raise e
    #     end
    #   end
    # end

    # def minus_file_monitor
    #   def plus_file_monitor
    #     redis = Attachment.redis
    #     field = self.b2_key
    #     lock_field = "lock:#{field}"

    #     begin
    #       if redis.set(lock_field, 1, ex: 5, nx: true)
    #         begin
    #           redis.pipelined do
    #             value = JSON.parse(redis.hget(Initial::MonitorKey, field) || '[]')

    #             value << -1
    #             redis.hset(Initial::MonitorKey, field, value.to_json)
    #           end
    #         ensure
    #           redis.del(lock_field)
    #         end
    #       else
    #         raise "获取锁失败"
    #       end
    #     rescue => e
    #       if e.message == "获取锁失败"
    #         sleep(3)
    #         retry
    #       else
    #         raise e
    #       end
    #     end
    #   end
    # end

    # def self.process_data arranged_data
    #   arranged_data.map do |folder, children|

    #     {
    #       id: folder.id,
    #       type: "folder",
    #       name: folder.folder_name,
    #       children: process_data(children) + attached_files_info(folder.attachments)
    #     }

    #   end
    # end

    # def self.attached_files_info(filelist)
    #   filelist.map do |file|
    #     {
    #       id: file.id,
    #       type: file.file_type,
    #       name: file.file_name,
    #       b2_key: file.b2_key,
    #       size: file.byte_size
    #     }
    #   end
    # end

    # def self.classify data, folder_items_id, attachment_items_id
    #   data.each do |item|
    #     if item[:type] == 'folder'
    #       folder_items_id << item["id"]
    #       classify item["children"], folder_items_id, attachment_items_id
    #     else
    #       attachment_items_id << item["id"]
    #     end
    #   end
    # end
end
