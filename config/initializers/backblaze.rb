require 'aws-sdk-s3'
configure = {
  region: Rails.application.credentials.dig(:aws, :AWS_REGION), # 从环境变量中获取区域信息
  endpoint: Rails.application.credentials.dig(:aws, :AWS_ENDPOINT_URL), # 从环境变量中获取端点URL
  access_key_id: Rails.application.credentials.dig(:aws, :AWS_ACCESS_KEY_ID), # 从环境变量中获取访问密钥ID
  secret_access_key: Rails.application.credentials.dig(:aws, :AWS_SECRET_ACCESS_KEY) # 从环境变量中获取秘密访问密钥
}
# 初始化 AWS S3 客户端
S3_Resource = Aws::S3::Resource.new(configure)
S3_Client = Aws::S3::Client.new(configure)
