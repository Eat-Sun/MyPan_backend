module Api
	module V1
		class Folders < Grape::API
			include Defualt

			resources :folders do

				desc "创建文件夹"
				params do
					use :token_validater
					requires :new_folder, type: { value: String, message: "请输入文件夹名"}
					requires :parent_folder_numbering, type: String
				end
				post 'newFolder' do
<<<<<<< HEAD
<<<<<<< HEAD

					user = User.get_user params[:token]

					if user
						response = Folder.create_folder(user, params[:parent_folder_numbering], params[:new_folder])
=======
					user_id = User.get_user params[:token]

					if user
						response = Folder.create_folder(user_id, params[:parent_folder_numbering], params[:new_folder])
>>>>>>> 添加回收站功能
=======
					user_id = User.get_user params[:token]

					if user
						response = Folder.create_folder(user_id, params[:parent_folder_numbering], params[:new_folder])
>>>>>>> 添加回收站功能
					else
						build_response(message: "用户不合法", exception: response.message)
					end

					if response.is_a?(Exception)
						build_response(message: "错误", exception: response.message)
					elsif response
						build_response(code: 1, data: response, message: "创建成功")
					else
						build_response(code: -1, data: nil, message: "创建失败")
					end
				end

				desc "删除文件夹"
				params do
					use :token_validater
					requires :target_folder_id, type: { value: String, message: "请输入文件夹名"}
				end
				post 'removeFolder' do
<<<<<<< HEAD
<<<<<<< HEAD
					user = User.get_user params[:token]
					if user
						response = Folder.delete_folder(user, params[:target_folder_id])
=======
=======
>>>>>>> 添加回收站功能
					user_id = User.get_user params[:token]

					if user_id
						response = Folder.delete_folder(params[:target_folder_id])
<<<<<<< HEAD
>>>>>>> 添加回收站功能
=======
>>>>>>> 添加回收站功能
					else
						build_response(message: "用户不合法", exception: response.message)
					end


					if response.is_a?(Exception)
				  	build_response(message: "错误", exception: response.message)
					elsif response == true
						build_response(code: 1, data: nil, message: "删除成功")
					else
						build_response(code: -1, data: nil, message: "删除失败")
					end
				end

			end

		end
	end
end
