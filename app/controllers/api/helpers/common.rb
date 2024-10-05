module Api
	module Helpers
		module Common
			extend ActiveSupport::Concern

			included do
				helpers do
					#api返回给前端的数据格式应该保持一致
					def build_response code: nil, data: nil, message: nil, exception: nil
						{
							code: code,
							data: data,
							message: message,
							exception: exception
						}
					end

					def get_or_set_cache key, value = nil
						result = Rails.cache.read key

						if result
							Rails.cache.touch key, expires_in: 1.day
							result
						else
							Rails.cache.fetch key, skip_nil: true do
								value
							end
						end

					end

					def get_user token
						decoded_token = OperateToken.decode_token token
						if decoded_token
							payload = decoded_token[0]
							return User.find(payload["user_id"])
						else
							return nil
						end
					end

					def classify data, folder_items_id, attachment_items_id
						data.each do |item|
							if item[:type] == 'folder'
								folder_items_id << item["id"]
								classify item["children"], folder_items_id, attachment_items_id
							else
								attachment_items_id << item["id"]
							end
						end
					end

					#定义了params中可选用的方法，这里定义了validation
					params :token_validater do
						requires :token, type: { value: String, message: "该操作需要提供token"}
					end

				end
			end


		end
	end
end
