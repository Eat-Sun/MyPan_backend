class UpdateFileMonitorJob < ApplicationJob

  def perform(*args)
    redis = Redis.new(url: "redis://localhost:6379/2")
    b2_keys = redis.smembers(Attachment::Initial::Monitor)
    key_values = redis.mapped_mget(*b2_keys)
    opt = key_values.map do |key, value|
      { b2_key: key, owner_count: value }
    end

    FileMonitor.upsert_all(opt, unique_by: :b2_key)

    Rails.cache.clear
  end
end
