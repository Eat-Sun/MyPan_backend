module Api
  module V1
    class UserData < Grape::API
      include Defualt

      resources :user_data do

        desc "获取文件夹及文件"
				params do
					use :token_validater
				end
				get 'getter' do
					user_id = Rails.cache.read params[:token]

					if user_id
						folder_data = Rails.cache.read user_id

						build_response(code: 1, data: folder_data, message: "读取成功")
					else
						build_response(code: -1, data: nil, message: "未登录")
					end

				end

        desc "移动文件夹及文件"
				params do
					use :token_validater
					requires :data, type: JSON do
						requires :filelist, type: { value: Array, message:"文件不能为空"}
						requires :target_folder_id, type: { value: Integer, message: "目标文件夹不能为空"}
					end
				end
				post 'mover' do
					user = User.get_user params[:token]

					if user
						folder_ids = []
						attachment_ids = []
						# p "params[:data][:filelist]",params[:data][:filelist]
						begin
							target_folder = Folder.find(params[:data][:target_folder_id])
							classify params[:data][:filelist], folder_ids, attachment_ids

							attachment_response = Attachment.move_attachments user, attachment_ids, target_folder
							folder_response = Folder.move_folders user, folder_ids, target_folder

							if attachment_response && folder_response
								build_response(code: 1, message: "移动成功")
							else
								build_response(code: 0, message: "移动失败，未能找到相关项", exception: "未能找到相关项")
							end
						rescue => e
							p "错误：",e.message
							build_response(code: 0, message: "错误", exception: e.message)
						end
					end
				end
      end
    end
  end
end
