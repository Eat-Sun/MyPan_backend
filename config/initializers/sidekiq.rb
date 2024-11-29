require 'sidekiq'
require 'sidekiq-cron'

schedule_file = "config/sidekiq.yml"
if File.exist?(schedule_file)
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)[:schedule]
end

Sidekiq.configure_server do |config|
  config.logger = Logger.new("log/sidekiq.log") # 指定日志文件路径
end
