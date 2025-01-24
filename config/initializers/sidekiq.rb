require 'sidekiq'
require 'sidekiq-cron'

redis_config = {
  url: ENV['SIDEKIQ_URL'] || 'redis://localhost:6379/2',
  password: Rails.application.credentials.dig(:REDIS_PASSWORD)
}
#服务器端
Sidekiq.configure_server do |config|
  config.redis = redis_config
  # config.logger = Logger.new("log/sidekiq.log")
end
#客户端
Sidekiq.configure_client do |config|
  config.redis = redis_config
end

schedule_file = "config/sidekiq.yml"
if File.exist?(schedule_file)
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)[:schedule]
end
