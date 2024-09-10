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
	def self.update_of_upload_for_database user, parent_folder, file_size, file_name, b2_key, file_type = 'undefined'
    allow_to_upload = ( user.used_space + file_size) < user.total_space

    attachment = nil
    if allow_to_upload
      begin
        transaction do
          attachment = parent_folder.attachments.create!(file_name: file_name, file_type: file_type, b2_key: b2_key, byte_size: file_size)
          user.update_column(:used_space, user.used_space + file_size)
        end
      rescue  => e
        p e.message
      end

      return {
        id: attachment.id,
        type: attachment.file_type,
        name: attachment.file_name,
        b2_key: attachment.b2_key,
        size: attachment.byte_size
      }
    else

      return false
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
      Rails.logger.error("下载文件时出现错误: #{e.message}")

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
      p e.message
      return e
    end

  end

	# 获取文件
  def self.get_filelist_from_backblaze user
    result = []
    folders_with_attachments = user.folders.includes(:attachments).to_a
    root = folders_with_attachments.find { |folder| folder.ancestry == nil}
    result << get_folders_and_files(folders_with_attachments, root)

    result
  end

  # 移动文件
  def self.move_attachments user, data, target_folder_id
    folders_item = []
    attachments_item = []
    data.each do |item|
      if item[:type] == 'folder'
        folders_item << item[:id]
      else
        attachments_item << item[:id]
      end
    end

    folders = Folder.where(id: folders_item)
    attachments = Attachment.where(id: attachments_item)
    target_folder = Folder.find(target_folder_id)

    begin
      if folders and attachments and target_folder
        transaction do
          folders.update_all(ancestry: target_folder.id)
          attachments.update_all(folder_id: target_folder.id)
        end

        return true
      else

        return false
      end
    rescue ActiveRecord::ActiveRecordError => e

      return e
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

      p "回调：", e.message
    end
  end

  private
  def minus_file_monitor
    begin

      FileMonitor.where(b2_key: self.b2_key).update_counters(owner_count: -1)
      FileMonitor.need_to_destroy
    rescue => e
      p "after_destroy回调:", e.message
    end

  end

  private
  def self.get_folders_and_files folders_with_attachments, parent_folder
    # p parent_folder
    {
      id: parent_folder.id,
      type: "folder",
      name: parent_folder.folder_name,
      children:
        get_children_folders(folders_with_attachments, parent_folder).map do |children_folder|
          get_folders_and_files(folders_with_attachments, children_folder)
        end + attached_files_info( parent_folder.attachments)

    }
  end

  private
  def self.get_children_folders folders, root
    folders.select{ |children| children.ancestry == root.id.to_s}
  end

  private
  def self.select_file attachments, file_type
    attachments.select{ |attachment| attachment.file_type == file_type.to_s }
  end

  private
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

  private
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

  # private
  # def self.remove_file user, files
  #   # p "files.class:",files.class
  #   file_size = files.map { |file| file.byte_size.to_i }.sum / 1048576.0

  #   if user
  #     transaction do
  #       begin
  #         user.used_space -= file_size
  #         user.save!(validate: false)

  #         file_monitors_id = files.map{ |file| file.file_monitor.id }
  #         # p "file_monitors_id:",file_monitors_id
  #         file_monitors = FileMonitor.joins("inner join attachments on attachments.id = file_monitors.attachment_id").where(id: file_monitors_id)
  #         # p "file_monitors:",file_monitors
  #         # p file_monitors.respond_to?(:update_all)
  #         file_monitors.update_all("owner_count = owner_count - 1")

  #         # p "file_monitors_update:",file_monitors
  #         conf = file_monitors.select { |file_monitor| file_monitor.owner_count <= 0 }
  #           .map { |file_monitor| {key: file_monitor.attachment.b2_key}  }

  #         RemoveFromB2Job.perform_later conf
  #         # p conf
  #         # S3_Resource.bucket(Initial::BucketName[:My_Pan]).delete_objects({
  #         #   delete: {
  #         #     objects: conf
  #         #   }
  #         # })
  #         files.destroy_all

  #         return true
  #       rescue => e
  #         puts "出现错误: #{e.message}"

  #         return e
  #       end
  #     end
  #   end

  # end


  #栈方式查询，未完成
  # def self.get_filelist_from_backblaze(user)
  #   result = []
  #   folders = user.folders.includes(:attachments).to_a
  #   roots = folders.select { |folder| folder.ancestry.nil? }

  #   roots.each do |root|
  #     stack = [[root, result]]

  #     until stack.empty?
  #       current_folder, current_result = stack.pop

  #       current_result << {
  #         id: current_folder.id,
  #         type: "folder",
  #         name: current_folder.folder_name,
  #         children: get_children_and_files(folders, current_folder)
  #       }
  #       current_folder.children.each do |child_folder|
  #         stack.push([child_folder, current_result])
  #       end
  #     end
  #   end

  #   result
  # end

  # private

  # def self.get_children_and_files(folders, folder)
  #   children_and_files = []

  #   folders.each do |child|
  #     if child.ancestry == folder.id.to_s
  #       children_and_files << {
  #         id: child.id,
  #         type: "folder",
  #         name: child.folder_name,
  #         children: []
  #       }
  #     end
  #   end

  #   attached_files_info(folder.attachments).each do |file_info|
  #     children_and_files << file_info
  #   end

  #   children_and_files
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

end
