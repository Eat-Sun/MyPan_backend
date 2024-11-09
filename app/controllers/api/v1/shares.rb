module Api
	module V1
		class Shares < Grape::API
			include Defualt

			resources :shares do
				desc "分享文件"
				params do
					use :token_validater
					requires :data, type: { value: Array, message: "文件不能为空"}
					requires :top, type: Array
					requires :varify, type: { value: Integer, message: "验证码不能为空"}
				end
				post 'new' do
					folder_opts = []
					attachment_opts = []
					user = User.get_user params[:token]
					top = params[:top].to_set

					share = Share.create!(user: user, link: params[:link], varify: params[:varify])
					params[:data].each do |item|
						is_top = top.include? item

						if item['type'] == 'folder'

							folder_opts << { folder_id: item['id'], share_id: share.id, top: is_top }
						else

							attachment_opts << { attachment_id: item['id'], share_id: share.id, top: is_top }
						end
					end
					response = Share.share_to_others(share, folder_opts, attachment_opts)

					if response.is_a?(Exception)
						build_response(message: "错误", exception: response.message)
					elsif response
						build_response(code: 1, data: response, message: "分享成功")
					else
						build_response(code: -1, data: response, message: "分享失败")
					end
				end

				desc "接收文件"
				params do
					use :token_validater
					requires :link, type: { value: String, message: "链接不能为空"}
					requires :varify, type: { value: String, message: "验证码不能为空"}
				end
				get 'getter' do
					user = User.get_user params[:token]

					if user
						response = Share.accept_from_others(user, params[:link], params[:varify])
					end

					if response.is_a?(Exception)
						build_response(message: "错误", exception: response.message)
					elsif response
						build_response(code: 1, data: response, message: "获取文件成功")
					else
						build_response(code: -1, data: response, message: "获取文件失败")
					end

				end

				desc "获取分享列表"
				params do
					use :token_validater
				end
				get 'shared' do
					user = User.get_user params[:token]

					if user
						response = Share.get_shares user
					end

					if response.is_a?(Exception)
						build_response(message: "错误", exception: response.message)
					elsif response
						build_response(code: 1, data: response, message: "获取分享列表成功")
					else
						build_response(code: -1, data: response, message: "获取分享列表失败")
					end
				end

				desc "取消分享"
				params do
					use :token_validater
					requires :link, type: { value: String, message: "链接不能为空"}
				end
				post 'concel' do
					user_id = Rails.cache.read params[:token]

					if user_id
						response = Share.cancel_shares params[:link]

						if response.is_a?(Exception)
							build_response(message: "错误", exception: response.message)
						elsif response
							build_response(code: 1, data: response, message: "取消分享成功")
						else
							build_response(code: -1, data: response, message: "取消分享失败")
						end
					end

				end
			end
		end
	end
end
