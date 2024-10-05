class Folder < ApplicationRecord
	extend FolderProcess::ProcessData

	belongs_to :user
  has_many :attachments, dependent: :destroy_async
  has_and_belongs_to_many :shares
	has_ancestry orphan_strategy: :destroy

	#创建文件夹
	def self.create_folder user, parent_folder_id, new_folder
		parent_folder = user.folders.find(parent_folder_id)

	  return false unless parent_folder

    begin
      new_children_folder = parent_folder.children.create(folder_name: new_folder, user: user)
    	if new_children_folder.persisted?
				# new_children_folder.create_file_monitor!(owner_count: 1)
				result = {
					id: new_children_folder.id,
					type: "folder",
					name: new_children_folder.folder_name,
					children:[]
				}

    		return result
    	else

    		return false
    	end
    rescue StandardError => e
			Folder.models_logger.error e.message

    	return e
    end
	end

	#处理分享文件夹
	def self.operate_share user, folders, attachments
		root = Folder.find_by(user: user, ancestry: nil)

		begin
			subtrees, top_attachments = set_subtree folders, attachments
			new_attachments = top_attachments.map do |top_attachment|
				{
					file_name: top_attachment.file_name,
					file_type: top_attachment.file_type,
					b2_key: top_attachment.b2_key,
					byte_size: top_attachment.byte_size
				}
			end

			# 处理顶层文件
			new = root.attachments.create(new_attachments)
			# 处理顶层文件夹
			processed = search_subtrees subtrees, root, user, attachments
			processed[0].concat(attached_files_info(new))

			return processed[0]
		rescue => e
			p "错误：", e.message
		end

	end

	#删除文件夹
	def self.delete_folder target_folders_id
		target_folders = Folder.where(id: target_folders_id)

		begin
			if target_folders.destroy_all

				return true
			else

				return false
			end
		rescue => e
			Folder.models_logger.error e.message

			return e
		end
	end

	#移动文件夹
	def self.move_folders user, folder_items_id, target_folder
		return true if folder_items_id.blank?

    folders = Folder.where(id: folder_items_id)

		begin
			if folders.present? and target_folder.present?
				folders.update_all(ancestry: target_folder.id)

				return true
			else

				return false
			end
		rescue => e
			Folder.models_logger.error e.message
			p "出错：", e.message
			raise e
		end
	end

	private
		def self.set_subtree folders, attachments
			begin
				top_folders = nil
				top_attachments = nil

				if folders.present?
					min_length = folders.min_by { |folder| folder.ancestry.length }.ancestry.length
					folder_attachments = []
					folders.each do |item|
						folder_attachments.concat(item.attachments)
					end

					top_folders = folders.select { |folder| folder.ancestry.length == min_length }
					(top_attachments = folder_attachments.present? ? attachments - folder_attachments : attachments) if attachments
				end

				tree = top_folders.map { |folder| folder.subtree.arrange }

				return [tree, top_attachments]
			rescue => e
				p "set_subtree", e.message
			end
		end

		def self.search_subtrees subtrees, parent, user, attachments
			# p "subtree", subtrees
			operated = subtrees.map do |subtree|

				operate_tree subtree, parent, user, attachments
			end

			return operated
		end

		def self.operate_tree subtree, parent, user, attachments
			begin
				result = subtree.map do |folder, children|
					# 创建新的文件夹和文件
					new_folder = parent.children.create!(folder_name: folder.folder_name, user: user)
					target_attachments = folder.attachments & attachments
					new_attachments = target_attachments.map do |new_attachment|
						{
							file_name: new_attachment.file_name,
							file_type: new_attachment.file_type,
							b2_key: new_attachment.b2_key,
							byte_size: new_attachment.byte_size
						}
					end

					attachments -= target_attachments
					new_files = new_folder.attachments.create(new_attachments)
					{
						id: new_folder.id,
						type: "folder",
						name: new_folder.folder_name,
						children: operate_tree(children, new_folder, user, attachments) + attached_files_info(new_files)
					}
				end

				return result
			rescue => e
				p "operate_tree", e.message
			end
		end
end
