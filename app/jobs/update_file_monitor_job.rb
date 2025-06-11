class UpdateFileMonitorJob < ApplicationJob
  def perform(*_args)
    redis = Redis.new(url: ENV['CACHE_URL'] || 'redis://localhost:6379/0',
                      password: Rails.application.credentials.dig(:REDIS_PASSWORD))

    opt = []
    while (key = redis.spop(Attachment::Initial::Monitor))
      value = redis.getdel key
      opt << { b2_key: key, owner_count: value }
    end

    result = FileMonitor.upsert_all(opt, unique_by: :b2_key, returning: Arel.sql('b2_key, id as file_monitor_id'))
    update_attachement result unless result.empty?
  end

  def update_attachement(result)
    values = result.map do |h|
      "(#{h['file_monitor_id']}, '#{ActiveRecord::Base.connection.quote_string(h['b2_key'])}')"
    end.join(',')

    sql = <<~SQL
      UPDATE attachments AS a
      SET file_monitor_id = v.file_monitor_id
      FROM (VALUES #{values}) AS v(file_monitor_id, b2_key)
      WHERE a.b2_key = v.b2_key
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end
