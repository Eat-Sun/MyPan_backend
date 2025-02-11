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
						data = Rails.cache.read user_id

						build_response(code: 1, data: data, message: "读取成功")
					else
						build_response(code: -1, data: nil, message: "未登录")
					end
				end

        desc "移动文件夹及文件"
				params do
					use :token_validater
					requires :target_folder_numbering, type: { value: String, message: "目标文件夹不能为空"}
					optional :folder_ids, type: { value: Array }
					requires :attachment_ids, type: { value: Array, message:"文件不能为空"}
				end
				post 'mover' do
					user_id = User.get_user params[:token], req: "id"

					if user_id
						begin
							target_folder = Folder.find_by(numbering: params[:target_folder_numbering])
							attachment_response = Attachment.move_attachments params[:attachment_ids], target_folder
							folder_response = Folder.move_folders params[:folder_ids], target_folder

							if attachment_response && folder_response
								build_response(code: 1, message: "移动成功")
							else
								build_response(code: 0, message: "移动失败，未能找到相关项", exception: "未能找到相关项")
							end
						rescue => e
							# p "错误：",e.message
							build_response(code: 0, message: "错误", exception: e.message)
						end
					end
				end
      end
    end
  end
end
