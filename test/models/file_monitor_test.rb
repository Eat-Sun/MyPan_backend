require "test_helper"

class AttachmentMonitorTest < ActiveSupport::TestCase
  setup do
    @redis = Redis.new(url: ENV['CACHE_URL'] || 'redis://localhost:6379/0', password: Rails.application.credentials.dig(:REDIS_PASSWORD))
    @redis.sadd("keys", "test:1")
    @redis.sadd("keys", "test:2")
    @redis.sadd("keys", "test:3")
    Rails.cache.increment('test:1')
    Rails.cache.increment('test:2')
    Rails.cache.increment('test:3')
  end

  # teardown do
  #   Rails.cache.clear
  # end

  test "the truth" do
    # threads = []
    # 10.times do |index|
    #   Thread.new do
    #     p @redis.sadd("set", "test")
    #   end
    # end
    # threads.each(&:join)
    key_values = @redis.smembers("keys")
    result = @redis.mapped_mget(*key_values)

    result = result.map do |key, value|
      { b2_key: key, owner_count: value }
    end
    # p result

    # assert_equal 1, result[1].map(&:to_i).sum
  end
end
