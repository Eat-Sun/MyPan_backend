require "test_helper"

class RemoveAttachmentAndFolderJobTest < ActiveJob::TestCase
  # fixtures :all
  setup do
    @user = users(:user1)
    @folder_ids = [111, 112]
    @attachment_ids = [11, 1111, 1112, 1121, 1122]
    @bin_ids = [1, 2, 3, 10, 11, 12, 13]
    @opt = [
      {
        mix_id: 11,
        type: "folder",
        is_top: true
      },
      {
        mix_id: 111,
        type: 'folder',
        is_top: true
      },
      {
        mix_id: 112,
        type: 'folder',
        is_top: true
      },
      {
        mix_id: 1111,
        type: 'undefined',
        is_top: false
      },
      {
        mix_id: 1112,
        type: 'word',
        is_top: false
      },
      {
        mix_id: 1121,
        type: 'undefined',
        is_top: false
      },
      {
        mix_id: 1122,
        type: 'word',
        is_top: false
      }
    ]

    FileService::RecycleService.add_to_bins(user_id: @user.id, folder_ids: @folder_ids, attachment_ids: @attachment_ids, opt: @opt)
  end
  test "the truth" do
    assert_enqueued_with(job: RemoveAttachmentAndFolderJob, args: [@folder_ids, @attachment_ids], queue: 'file_operation')do
      RemoveAttachmentAndFolderJob.perform_later(@folder_ids, @attachment_ids)
    end
    perform_enqueued_jobs


  end
end
