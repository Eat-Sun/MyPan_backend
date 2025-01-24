class Share < ApplicationRecord
	extend FolderProcess::ProcessData
	include Skylight::Helpers

	belongs_to :user
	has_many :attachments_shares, class_name: "AttachmentShare", dependent: :delete_all
	has_many :attachments, through: :attachments_shares
	has_many :folders_shares, class_name: "FolderShare", dependent: :delete_all
	has_many :folders, through: :folders_shares

	validates_presence_of :varify, message: "验证码不能为空"

	before_save :default

	#分享文件
	def self.share_to_others share, folder_opts, attachment_opts
		# Skylight.instrument title: "share_to_others" do
			begin
				if folder_opts.any? || attachment_opts.any?
					transaction do
						FolderShare.insert_all!(folder_opts)
						AttachmentShare.insert_all!(attachment_opts)
					end

					result = {
						share: share.id,
						link: share.link,
						varify: share.varify
					}
					return result
				else

					return false
				end

			rescue => e
				Share.models_logger.error e.message
				# p "错误", e.message
				return e
			end
		# end
	end

	#接收文件
	def self.accept_from_others(user_id, link, varify)
		begin
			share = Share.find_by!(link: link)
			root = Folder.find_by!(user_id: user_id, folder_name: 'root')

			if share && share.varify == varify
				new_folders_with_attachments = get_folders_with_attachments user_id, share, root
				# p new_folders_with_attachments
				new_attachments = get_top_attachments share, root

				folders = nil
				attachments = nil
				transaction do
					folders = Folder.create!(new_folders_with_attachments)
					attachments = Attachment.create!(new_attachments)
				end

				folders = folders.map do |folder|
          {
            id: folder[:id],
            type: 'folder',
            name: folder[:folder_name],
            numbering: folder[:numbering],
            ancestry: folder[:ancestry],
            children: []
          }
				end
				# p Attachment.where(folder_id: folders.map{ |folder| folder[:id] })
				attachments = attachments
					.concat(Attachment.where(folder_id: folders.map{ |folder| folder[:id] }))
					.map do |attachment|
						{
							id: attachment[:id],
							folder_id: attachment[:folder_id],
							type: attachment[:file_type],
							name: attachment[:file_name],
							b2_key: attachment[:b2_key],
							byte_size: attachment[:byte_size]
						}
					end

				return [folders, attachments]
			end
		rescue => e
			Share.models_logger.error e.message
			return e
		end
	end

  #取消分享
  def self.cancel_shares(link)
		shares = Share.where(link: link)

		begin

			return true if shares.destroy_all
			return false
		rescue => e
			Share.models_logger.error e.message
			# p e.message
			return e
		end
  end

  #获取当前分享
  def self.get_shares user_id
		shares = Share.where(user: user_id)
		shared_attachments = []

		shares.each do |share|
			shared_attachments.push({
				link: share.link,
				varify: share.varify,
				attachments: attached_files_info(share.attachments)
			})
		end

		return shared_attachments
  end

	private
		def default
			self.link = SecureRandom.alphanumeric(8)
			self.expires_at = 7.days.from_now
		end

		# def self.get_folders_data share: nil
		# 	Folder.joins(:shares).where("shares.id = ?", share.id)
		# 		.pluck(:id, :folder_name, :ancestry, Arel.sql("folders_shares.top as is_top"))

		# end

		# def self.get_attachments_data share: nil
		# 	Attachment.joins(:shares).where("shares.id = ?", share.id)
		# 		.pluck(:folder_id,  Arel.sql("attachments_shares.top as is_top"))
		# end

		# def self.arrange_data user_id: user_id, folders: nil, attachments: nil
		# 	stack = []
		# 	folders.map do |folder|
		# 		Folder.new(user_id: user_id, folder_name: folder[1])
		# 	end
		# end

		def self.get_folders_with_attachments user_id, share, root
			result = Folder.left_joins(:attachments, :shares)
				.select("jsonb_build_object(
						'folder_name', folders.folder_name,
						'numbering', folders.numbering,
						'ancestry', folders.ancestry,
						'top', folders_shares.top,
						'attachments', jsonb_agg(jsonb_build_object(
							'file_name', attachments.file_name,
							'file_type', attachments.file_type,
							'b2_key', attachments.b2_key,
							'byte_size', attachments.byte_size,
							'file_monitor_id', attachments.file_monitor_id
						))
				) AS result")
				.where("shares.id = ?", share.id)
				.group("folders.id, folders_shares.top")
				.map do |folder|
					item = {
						user_id: user_id,
						folder_name: folder.result["folder_name"],
						numbering: folder.result["numbering"],
						ancestry: folder.result["top"] == true ? root.numbering : folder.result["ancestry"],
						in_bins: false
					}

					if(folder.result["attachments"][0]["b2_key"])
						item[:attachments] = folder.result["attachments"].map do |attachment|
							Attachment.new(
								file_name: attachment["file_name"],
								file_type: attachment["file_type"],
								b2_key: attachment["b2_key"],
								byte_size: attachment["byte_size"],
								file_monitor_id: attachment["file_monitor_id"],
								in_bins: false
							) if attachment["b2_key"]
						end
					end

					item
				end
		end

		def self.build_attachments attachments

		end

		def self.get_top_attachments share, root
			share.attachments.joins(:attachments_shares).where(attachments_shares: { top: true })
				.pluck(:file_name, :file_type, :b2_key, :byte_size, :file_monitor_id)
				.map do |attachment|
					{
						folder_id: root.id,
						file_name: attachment[0],
						file_type: attachment[1],
						b2_key: attachment[2],
						byte_size: attachment[3],
						file_monitor_id: attachment[4],
						in_bins: false
					}
				end
		end

		# def self.stack_process user, folders, attachments
		# 	begin
		# 		tree = { root: true, children: [] }
		# 		root = Folder.find_by(user_id: user.id, ancestry: nil)
		# 		top_attachments = attachments.select { |attachment| attachment.attachments_shares.first.top == true }
		# 		stack = folders.select { |folder| folder.folders_shares.first.top == true }.map do |folder|
		# 			{ folder: folder, parent_node: tree, parent: nil  }
		# 		end

		# 		new_top = top_attachments.map do |top_attachments|
		# 			{
		# 				folder_id: root.id,
		# 				file_name: top_attachments.file_name,
		# 				file_type: top_attachments.file_type,
		# 				b2_key: top_attachments.b2_key,
		# 				byte_size: top_attachments.byte_size,
		# 				file_monitor_id: top_attachments.file_monitor_id
		# 			}
		# 		end
		# 		new_top = root.attachments.create!(new_top)

		# 		while stack.any?
		# 			item = stack.pop
		# 			folder = item[:folder]
		# 			parent = item[:parent]
		# 			parent_node = item[:parent_node]

		# 			new_folder = if parent_node.has_key?(:root)
		# 				root.children.create!(user_id: user.id, folder_name: folder.folder_name)
		# 			else
		# 				parent.children.create!(user_id: user.id, folder_name: folder.folder_name)
		# 			end
		# 			new_attachments = folder.attachments.map do |attachment|
		# 				{
		# 					folder_id: new_folder.id,
		# 					file_name: attachment.file_name,
		# 					file_type: attachment.file_type,
		# 					b2_key: attachment.b2_key,
		# 					byte_size: attachment.byte_size,
		# 					file_monitor_id: attachment.file_monitor_id
		# 				}
		# 			end
		# 			new_attachments = new_folder.attachments.create!(new_attachments)

		# 			node = {
		# 				id: new_folder.id,
		# 				type: "folder",
		# 				name: folder.folder_name,
		# 				children: attached_files_info(new_attachments)
		# 			}
		# 			parent_node[:children] << node

		# 			if folder.has_children?
		# 				folder.children.each do |child|
		# 					stack.push({ folder: child, parent_node: node, parent: new_folder })
		# 				end
		# 			end
		# 		end
		# 		tree[:children].push(*attached_files_info(new_top))

		# 		return tree[:children]
		# 	rescue => e

		# 		return e
		# 	end
		# end
end
