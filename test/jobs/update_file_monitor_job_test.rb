require "test_helper"

class UpdateFileMonitorJobTest < ActiveJob::TestCase
  test "the truth" do
    Rails.cache.write("update_filemonitor", {"fG56hI"=>[1, -1], "jK78lM"=>[1, -1], "vW34xY"=>[1, -1], "zA56bC"=>[1, -1], "Ag3Wg1"=>[1], "zB56dE"=>[1], "wvWE20"=>[1, 1], "dwaW3B"=>[1, 1]})
    #先断言作业是否被入队
    assert_enqueued_with(job: UpdateFileMonitorJob) do
      UpdateFileMonitorJob.perform_later
    end
    #再执行队列中的作业
    perform_enqueued_jobs

    assert_equal [1, 1, 1, 1, 2, 2, 3, 3], FileMonitor.where(id: [1, 2, 5, 6, 11, 12, 9, 10]).pluck(:owner_count)
  end
end
