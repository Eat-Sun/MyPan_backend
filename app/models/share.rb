class Share < ApplicationRecord
	has_and_belongs_to_many :attachments
	has_and_belongs_to_many :folders

	validates_presence_of :varify, message: "验证码不能为空"

	before_create :default

	#分享文件
  def self.share_to_others(data, varify)
		p "data:",data
		# share = nil
		# folders_id = []
		# attachments_id = []
		# data.each do |item|
		# 	if item[:type] == 'folder'
		# 		folders_id << item[:id]
		# 	else
		# 		attachments_id << item[:id]
		# 	end
		# end
		# # p "folders_id:", folders_id
		# # p "attachments_id:", attachments_id
		# begin
		# 	transaction do
		# 		share = Share.create!(varify: varify)

		# 		if folders_id.present?
		# 			# p "folders:", folders_id
		# 			folders = Folder.includes(:attachments).where(id: folders_id)
		# 			included_attachments_id = folders.flat_map do |folder|
		# 				folder.attachments.ids
		# 			end

		# 			share.folders << folders

		# 			attachments_id -= included_attachments_id
		# 		end
		# 		if attachments_id.present?
		# 			# p "attachments:", attachments_id
		# 			attachments = Attachment.where(id: attachments_id)

		# 			share.attachments << attachments
		# 		end
		# 	end

		# 	result = {
		# 		share: share.id,
		# 		link: share.link,
		# 		varify: share.varify
		# 	}
		# 	return result
		# rescue => e
		# 	p e.message
		# 	# p "Backtrace: #{e.backtrace}"
		# end
  end

  #接收文件
  def self.accept_from_others(user, link, varify)
  	share = Share.includes( attachments: :file_monitor, folders: :attachments).find_by(link: link)

		if share and share.varify == varify
			root_folder = user.folders.roots.first
			target_folders = share.folders
			target_attachments = share.attachments.map do |attachment|
				{
					file_name: attachment.file_name,
					file_type: attachment.file_type,
					b2_key: attachment.b2_key,
					byte_size: attachment.byte_size
				}
			end

			begin
				transaction do
					if target_folders.present?
						target_folders.each do |folder|
							new_folder = root_folder.children.create(folder_name: folder.folder_name, user: user)
							new_attachments = folder.attachments.map do |attachment|
								{
									file_name: attachment.file_name,
									file_type: attachment.file_type,
									b2_key: attachment.b2_key,
									byte_size: attachment.byte_size
								}
							end

							new_folder.attachments.create!(new_attachments)
						end
					end

					root_folder.attachments.create!(target_attachments) if target_attachments.present?
	  		end

	  		return Attachment.get_filelist_from_backblaze user
			rescue => e
				p "出现错误：#{e.message}"
			end

		else

			return false
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
