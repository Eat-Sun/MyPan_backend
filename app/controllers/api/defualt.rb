module Api
	module Defualt
		extend ActiveSupport::Concern

		included do
			include Helpers::Common

			#默认支持四种返回格式，如果显示声明，那么只会支持显示声明的格式
			#content_type :json, 'application/json'
			#content_type :xml, 'application/xml'
			#content_type :txt, 'text/plain'
			#content_type :binary, 'application/octet-stream'

			default_format :json #定义默认数据结构

			#在此处定义了api的版本，会影响到下面所有的api
			#using指定了版本体现的方式，此处表示版本信息会体现在api路径中，/api/v1/api_path
			version 'v1', using: :path

			#异常抓取
			rescue_from ActiveRecord::RecordNotFound do | e|
				error! 'record not found', 404
			end


		end
	end
end
