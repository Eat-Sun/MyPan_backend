require "test_helper"

class UpdateFileMonitorJobTest < ActiveJob::TestCase
  setup do
    redis = Redis.new(url: ENV['CACHE_URL'] || 'redis://localhost:6379/0', password: Rails.application.credentials.dig(:REDIS_PASSWORD))
    members = ["wvWE20", "dwaW3B", "xYz12A", "bC34dE", "fG56hI", "New"]
    redis.sadd(Attachment::Initial::Monitor, *members)
    Rails.cache.increment("wvWE20", 1)
    Rails.cache.increment("dwaW3B", 2)
    Rails.cache.increment("xYz12A", 3)
    Rails.cache.increment("bC34dE", 4)
    Rails.cache.increment("fG56hI", 5)
    Rails.cache.increment("New", 6)

  end

  test "the truth" do
    #先断言作业是否被入队
    assert_enqueued_with(job: UpdateFileMonitorJob) do
      UpdateFileMonitorJob.perform_later
    end
    #再执行队列中的作业
    perform_enqueued_jobs

    p FileMonitor.where(id: [1, 2, 3, 4, 5, 26]).pluck(:id, :owner_count)
    # assert_equal [1, 1, 1, 1, 2, 2, 3, 3], FileMonitor.where(id: [1, 2, 5, 6, 11, 12, 9, 10]).pluck(:owner_count)
  end
end
