module RedisPool

  class << self

    def redis
      @redis ||= ConnectionPool.new(size: 5, timeout: 5) do
        Redis.new(url: 'redis://localhost:6379/2')
      end
    end
  end
end
