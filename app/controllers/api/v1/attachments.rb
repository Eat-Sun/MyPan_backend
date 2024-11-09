module Api
	module V1
		class Attachments < Grape::API
			include Defualt

			resources :attachments do
				# desc "上传文件"
        # params do
        #   use :token_validater
        #   requires :file, type: { value: File, message: "文件不能为空" }
				# 	requires :parent_folder_id, type: { value: Integer, message: "父文件夹不能为空" }
        #   optional :file_type, type: { value: String, message: "文件类型不能为空"}
        # end
				# post 'uploader' do
				# 	user = get_user params[:token]
				# 	parent_folder = Folder.find params[:parent_folder_id]

				# 	if user
				# 		response = Attachment.upload_to_backblaze( user, parent_folder, params[:file], params[:file_type])
				# 	else
				# 		build_response(message: "用户不合法", exception: response.message)
				# 	end

			  # 	if response.is_a?(Exception)
			  # 		build_response(message: "错误", exception: response.message)
			  # 	elsif response
			  # 		build_response(code: 1, data: response, message: "上传成功")
			  # 	else
			  # 		build_response(code: -1, data: nil, message: "上传失败")
			  # 	end
				# end

				desc "下载文件"
				params do
					requires :b2_keys, type: { value: Array, message: "不能为空" }
				end
				get 'downloader' do
					response = Attachment.download_from_blackblaze params[:b2_keys]

					if response.is_a?(Exception)
					  build_response(message: "错误", exception: response.message)
					elsif response
					  build_response(code: 1, data: response, message: "下载请求提交成功")
					else
					  build_response(code: -1, data: nil, message: "下载请求提交失败")
					end

				end

				desc "删除文件"
				params do
					use :token_validater
					requires :data, type: { value: Array, message: "文件不能为空"}
				end
				post 'deleter' do
					folder_ids = []
					attachement_ids = []
					classify params[:data], folder_ids, attachement_ids
					p folder_ids
					p attachement_ids

					response = Attachment.update_of_destroy_for_database(folder_ids, attachement_ids)

					if response.is_a?(Exception)
					  build_response(message: "错误", exception: response.message)
					elsif response
					  build_response(code: 1, data: response, message: "删除成功")
					else
					  build_response(code: -1, data: nil, message: "删除失败")
					end

				end

				# desc "获取文件夹及文件"
				# params do
				# 	use :token_validater
				# end
				# get 'getter' do
				# 	user_id = Rails.cache.read params[:token]

				# 	if user_id
				# 		folder_data = Rails.cache.read user_id

				# 		build_response(code: 1, data: folder_data, message: "读取成功")
				# 	else
				# 		build_response(code: -1, data: nil, message: "未登录")
				# 	end

				# end

				# desc "移动文件"
				# params do
				# 	use :token_validater
				# 	requires :data, type: JSON do
				# 		requires :filelist, type: { value: Array, message:"文件不能为空"}
				# 		requires :target_folder_id, type: { value: Integer, message: "目标文件夹不能为空"}
				# 	end
				# end
				# post 'mover' do
				# 	user = get_user params[:token]

				# 	if user
				# 		folder_items_id = []
				# 		attachment_items_id = []
				# 		# p "params[:data][:filelist]",params[:data][:filelist]
				# 		begin
				# 			target_folder = Folder.find(params[:data][:target_folder_id])
				# 			classify params[:data][:filelist], folder_items_id, attachment_items_id

				# 			attachment_response = Attachment.move_attachments user, attachment_items_id, target_folder
				# 			folder_response = Folder.move_folders user, folder_items_id, target_folder

				# 			if attachment_response && folder_response
				# 				build_response(code: 1, message: "移动成功")
				# 			else
				# 				build_response(code: 0, message: "移动失败，未能找到相关项")
				# 			end
				# 		rescue => e
				# 			# p "错误：",e.message
				# 			build_response(code: 0, message: "错误", exception: e.message)
				# 		end
				# 	end
				# end

			end

		end
	end
end
