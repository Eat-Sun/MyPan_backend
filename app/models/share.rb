class Share < ApplicationRecord
	extend FolderProcess::ProcessData

	belongs_to :user
	has_and_belongs_to_many :attachments
	has_and_belongs_to_many :folders

	validates_presence_of :varify, message: "验证码不能为空"

	before_save :default

	#分享文件
	def self.share_to_others varify, folder_items_id, attachment_items_id
		all_folder = []
		all_attachment = []

		if folder_items_id.present?
			Folder.includes(:attachments).find(folder_items_id).each do |folder|
				subtree = folder.subtree

				subtree.each do |item|
					all_attachment.concat(item.attachment_ids)
				end
				all_folder.concat(folder.subtree_ids)
				# p "folder.attachment_ids", folder.attachment_ids
			end
		end
		all_attachment.concat(attachment_items_id)
		# p "all_folder", all_folder
		# p "all_attachment", all_attachment

		share = nil
		begin
			transaction do
				share = Share.new(varify: varify)

				share.folder_ids = all_folder if all_folder.present?
				share.attachment_ids = all_attachment if all_folder.present?

				share.save!
			end

			result = {
				share: share.id,
				link: share.link,
				varify: share.varify
			}
			return result
		rescue => e
			Share.models_logger.error e.message
			p "错误", e.message
			return e
		end
	end

	#接收文件
	def self.accept_from_others(user, link, varify)
		begin
			share = Share.includes(:folders, attachments: :file_monitor).find_by(link: link)

			if share.varify == varify
				folders = share.folders
				attachments = share.attachments
				# p "folders", folders
				# p "attachments", attachments
				processed_data = Folder.operate_share user, folders, attachments

				return processed_data
			else

				return false
			end
		rescue => e
			p "错误", e.message
		end
	end

  #取消分享
  def self.cancel_shares(user, shares)
  	shares
  end

  #获取当前分享
  def self.get_shares user
  	shared_folders = Share.includes( :folders).where(folders: { user_id: user.id})
		shared_attachments = Share.includes(attachments: :folder).where(folders: { user_id: user.id})
  	result = []

  	shared_folders.each do |share|
  		result << {
  			id: share.id,
  			link: share.link,
  			varify: share.varify,
  			children: share.folders
  		}
  	end
  	shared_attachments.each do |share|
  		result << {
  			id: share.id,
  			link: share.link,
  			varify: share.varify,
  			children: share.attachments
  		}
  	end

  	return result
  end

	private
		def default
			self.link = SecureRandom.alphanumeric(8)
			self.expires_at = 7.days.from_now

		end
end
