class UpdateFileMonitorJob < ApplicationJob

  def perform(*args)
    redis = Redis.new(url: ENV['CACHE_URL'] || 'redis://localhost:6379/0', password: Rails.application.credentials.dig(:REDIS_PASSWORD))
    b2_keys = redis.smembers(Attachment::Initial::Monitor)
    if b2_keys.any?
      key_values = redis.mapped_mget(*b2_keys)
      opt = key_values.map do |key, value|
        Rails.cache.decrement(key, value)
        { b2_key: key, owner_count: value }
      end

      reulst = FileMonitor.upsert_all(opt, unique_by: :b2_key)
    else
      return
    end
  end
end
