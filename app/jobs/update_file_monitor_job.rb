class UpdateFileMonitorJob < ApplicationJob

  def perform(*args)
    redis = Redis.new(url: "redis://localhost:6379/2")
    update_data = redis.hgetall "update_filemonitor"

    unless update_data.blank?

      update_data.each do |key, value|
        value = Marshal.load(value)
        FileMonitor.find_or_create_by!(b2_key: key).increment!(:owner_count, value.sum)
      end

      redis.del "update_filemonitor"
    end
  end
end
