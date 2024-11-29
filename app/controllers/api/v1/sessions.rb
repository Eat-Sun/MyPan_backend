module Api
	module V1
		class Sessions < Grape::API
			include Defualt

			resources :sessions do

				desc "登陆"
				params do
					requires :user, type: Hash do
						requires :username, allow_blank: true, desc: "用户名"
						requires :password, allow_blank: true, desc: "密码"
					end
					optional :token
				end
				post 'create' do
					# if params[:user]
						user = User.authenticate(params[:user][:username], params[:user][:password])

						if user
							folder_data = Rails.cache.read(user.id) || FileService.get_filelist_from_backblaze(user)
							free_space = User.get_free_space user.id
							token = nil

							if folder_data
								Rails.cache.fetch user.id do
									{ folder_data: folder_data, free_space: free_space }
								end
							end
							if params[:token].present?
								decoded_token = OperateToken.decode_token params[:token]
								# 检查解码结果是否有效
								if decoded_token
									token_payload = decoded_token.first
									if token_payload["user_id"] == user.id
										# 老用户，使用现有的 token
										token = params[:token]
									else
										# 新用户，生成新的 token
										token = OperateToken.generate_token(user.id)
									end
								else
									# Token 解码失败或者过期，生成新的 token
									token = OperateToken.generate_token(user.id)
								end
							else
								# 没有传递 token，生成新的 token
								token = OperateToken.generate_token(user.id)
							end
							Rails.cache.write token, user.id

							build_response(code: 1, data: { token: token}, message: "登陆成功")
						else

							build_response(code: -1, message: "用户名或密码错误")
						end

				end

				desc "退出登陆"
				params do
					use :token_validater
					requires :data, type: JSON do
						requires :folder_data, { type: JSON, message: "文件数据缺失" }
						requires :free_space, { type: Integer, message: "剩余空间缺失" }
					end
				end
				post 'quit' do
					begin
						user_id = Rails.cache.read params[:token]

						if user_id
							Rails.cache.write params[:token], user_id
<<<<<<< HEAD
<<<<<<< HEAD
							Rails.cache.write user_id, params[:folder_data]
							p params[:folder_data]
=======
							Rails.cache.write user_id, params[:data]
							p params[:data]
							status 200
>>>>>>> 添加回收站功能
=======
							Rails.cache.write user_id, params[:data]
							p params[:data]
							status 200
>>>>>>> 添加回收站功能
						end

					rescue => e
						p e.message
					end

				end

			end


		end
	end
end
