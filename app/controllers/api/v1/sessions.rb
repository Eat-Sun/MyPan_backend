module Api
	module V1
		class Sessions < Grape::API
			include Defualt

			helpers do
				# def generate_token(user_id)
				# 	payload = { user_id: user_id }
				# 	JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
				# end

			end

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
							folder_data = Rails.cache.read(user.id) || Attachment.get_filelist_from_backblaze(user)
							token = nil

							if folder_data
								Rails.cache.fetch user.id do
									folder_data
								end
							end
							if params[:token].present?
								decoded_token = OperateToken.decode_token params[:token]
								# 检查解码结果是否有效
								if decoded_token
									token_payload = decoded_token.first
									if token_payload["user_id"] == user.id
										# Token与当前user匹配，使用现有的 token
										token = params[:token]
									else
										# Token与当前user不匹配，生成新的 token
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
					requires :folder_data, type: { value: JSON, message: "文件数据不能为空" }
				end
				post 'quit' do
					begin
						user_id = Rails.cache.read params[:token]

						if user_id
							Rails.cache.write params[:token], user_id
							Rails.cache.write user_id, params[:folder_data]
						end

					rescue => e
						p e.message
					end

				end

			end


		end
	end
end
