module Api
	module V1
		class Shares < Grape::API
			include Defualt

			resources :shares do
				desc "分享文件"
				params do
					use :token_validater
					requires :data, type: { value: Array, message: "文件不能为空"}
					requires :varify, type: { value: String, message: "验证码不能为空"}
				end
				post 'new' do
					# puts params[:data]
					folder_items_id = []
					attachment_items_id = []
					user = get_user params[:token]

					params[:data].each do |item|
						if item['type'] == 'folder'
							folder_items_id << item['id']
						else
							attachment_items_id << item['id']
						end
					end

					if user
						response = Share.share_to_others(params[:varify], folder_items_id, attachment_items_id)
					end

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
					user = get_user params[:token]

					if user
						response = Share.accept_from_others( user, params[:link], params[:varify])
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
					user = get_user params[:token]

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
			end

		end
	end
end
