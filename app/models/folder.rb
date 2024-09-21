class Folder < ApplicationRecord
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

    	return e
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

			return e
		end

	end

end
