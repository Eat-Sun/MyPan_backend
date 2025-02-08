class Folder < ApplicationRecord
  include ActsAsTree
  extend FolderProcess::ProcessData

  belongs_to :user
  has_many :attachments
  has_many :folders_shares, class_name: "FolderShare", dependent: :delete_all
  has_many :shares, through: :folders_shares

  scope :in_bins, -> { where(:in_bins => true).pluck(:id) }

  acts_as_tree primary_key: 'numbering', foreign_key: 'ancestry'

  #创建文件夹
  def self.create_folder user_id, parent_folder_numbering, new_folder_name
    parent_folder = Folder.find_by!(user_id: user_id, numbering: parent_folder_numbering)

    return false unless parent_folder

    begin
      numbering = generate_numbering user_id
      new_children_folder = parent_folder.children.create!(user_id: user_id, folder_name: new_folder_name, numbering: numbering, in_bins: false)
      if new_children_folder.persisted?
        result = {
          id: new_children_folder.id,
          type: "folder",
          name: new_children_folder.folder_name,
          numbering: new_children_folder.numbering,
          ancestry: new_children_folder.ancestry,
          children: []
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

  #删除文件夹
  def self.delete_folder folder_ids
    target_folders = Folder.where(id: folder_ids)

    begin
      if target_folders.delete_all

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
  def self.move_folders folder_items_id, target_folder
    return true if folder_items_id.blank?

    folders = Folder.where(id: folder_items_id)

    begin
      if folders.present? and target_folder.present?
        folders.update_all(ancestry: target_folder.numbering)

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

  #获取活跃文件夹
  def self.get_active_folders user:
    folders = user.folders.where(in_bins: false)
      .pluck("id, folder_name, numbering, ancestry")
      .map do |folder|
        {
          id: folder[0],
          type: 'folder',
          name: folder[1],
          numbering: folder[2],
          ancestry: folder[3],
          children: []
        }
      end
  end

  #获取回收文件夹
  def self.get_recycled user_id
    folders = Folder.joins("INNER JOIN recycle_bins ON recycle_bins.user_id = folders.user_id AND recycle_bins.mix_id = folders.id").
      where(user_id: user_id, in_bins: true).
      where("recycle_bins.type = 'folder'").
      pluck("recycle_bins.id", :id, :folder_name, :numbering, :ancestry, "recycle_bins.is_top")
      .map do |item|
        {
          id: item[0],
          mix_id: item[1],
          type: 'folder',
          name: item[2],
          numbering: item[3],
          ancestry: item[4],
          is_top: item[5],
          children: []
        }
      end
  end

  #从回收站恢复
  def self.restore_from_bin folders:
    ids = folders[:ids]
    top_ids = folders[:top_ids]
    ancestry = folders[:ancestry]

    where(id: ids).update_all([
      "in_bins = false, ancestry = CASE WHEN id IN (?) THEN ? ELSE ancestry END",
      top_ids, ancestry
    ])
  end

  private
  def self.generate_numbering user_id
    user_id.to_s << '_' << SecureRandom.alphanumeric(4).to_s
  end
    # def self.set_subtree folders, attachments
    # 	begin
    # 		tree = []
    # 		folder_attachments = []

    # 		if folders.present?
    # 			min_length = folders.min_by { |folder| folder.ancestry.length }.ancestry.length
    # 			folders.each do |item|
    # 				folder_attachments.concat(item.attachments)
    # 			end

    # 			top_folders = folders.select { |folder| folder.ancestry.length == min_length }
    # 			tree = top_folders.map { |folder| folder.subtree.arrange }
    # 		end
    # 		top_attachments = attachments - folder_attachments

    # 		return [tree, top_attachments]
    # 	rescue => e
    # 		p "set_subtree", e.message
    # 	end
    # end

    # def self.search_subtrees subtrees, parent, user, attachments
    # 	operated = subtrees.map do |subtree|

    # 		operate_tree subtree, parent, user, attachments
    # 	end

    # 	return operated
    # end

    # def self.operate_tree subtree, parent, user, attachments
    # 	begin
    # 		result = subtree.map do |folder, children|
    # 			# 创建新的文件夹和文件
    # 			new_folder = parent.children.create!(folder_name: folder.folder_name, user: user)
    # 			target_attachments = folder.attachments & attachments
    # 			new_attachments = target_attachments.map do |new_attachment|
    # 				{
    # 					file_name: new_attachment.file_name,
    # 					file_type: new_attachment.file_type,
    # 					b2_key: new_attachment.b2_key,
    # 					byte_size: new_attachment.byte_size
    # 				}
    # 			end

    # 			attachments -= target_attachments
    # 			new_files = new_folder.attachments.create(new_attachments)
    # 			{
    # 				id: new_folder.id,
    # 				type: "folder",
    # 				name: new_folder.folder_name,
    # 				children: operate_tree(children, new_folder, user, attachments) + attached_files_info(new_files)
    # 			}
    # 		end

    # 		return result
    # 	rescue => e
    # 		p "operate_tree", e.message
    # 	end
    # end
end
