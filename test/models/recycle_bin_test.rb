require "test_helper"

class RecycleBinTest < ActiveSupport::TestCase
  setup do
    @user = users(:user1)
    @folder_ids = [111, 112]
    @attachment_ids = [11, 1111, 1112, 1121, 1122]
    @bin_ids = [1, 2, 3, 4, 5, 6, 7]
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
  end
  test "添加到回收站" do
    p Folder.where(id: @attachment_ids).update_all(
      ["in_bins = false, ancestry = CASE WHEN id IN (?) THEN ? ELSE ancestry END",
      [1, 2, 3], "ancestry"]
    ).to_sql
    result = FileService::RecycleService.add_to_bins(user_id: @user.id, folder_ids: @folder_ids, attachment_ids: @attachment_ids, opt: @opt)
    pp result
    # 验证数据库更新操作是否成功
    assert result

    folders = Folder.where(id: @folder_ids).pluck(:id, :in_bins)
    attachments = Attachment.where(id: @attachment_ids).pluck(:id, :in_bins)
    folders.each { |folder| assert_equal true, folder[1], "Folder #{folder[0]} should be in bins" }
    attachments.each { |attachment| assert_equal true, attachment[1], "Attachment #{attachment[0]} should be in bins" }

    recycled = RecycleBin.where(user_id: @user.id).pluck(:id)
    assert_equal [1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21], recycled
  end

  test "恢复文件" do
    folder_ids = [111, 112]
    attachment_ids = [1111, 1112]
    FileService::RecycleService.add_to_bins(user_id: @user.id, folder_ids: @folder_ids, attachment_ids: @attachment_ids, opt: @opt)
    result = FileService::RecycleService.restore(folder_ids: @folder_ids, attachment_ids: @attachment_ids, bin_ids: @bin_ids)
    # 验证数据库更新操作是否成功
    assert result

    folders = Folder.where(id: folder_ids).pluck(:id, :in_bins)
    attachments = Attachment.where(id: attachment_ids).pluck(:id, :in_bins)
    folders.each { |folder| assert_equal false, folder[1], "Folder #{folder[0]} should be restored" }
    attachments.each { |attachment| assert_equal false, attachment[1], "Attachment #{attachment[0]} should be restored" }
  end

  test "彻底删除文件" do
    FileService::RecycleService.add_to_bins(user_id: @user.id, folder_ids: @folder_ids, attachment_ids: @attachment_ids, opt: @opt)
    result = FileService::RecycleService.remove(folder_ids: @folder_ids, attachment_ids: @attachment_ids, bin_ids: @bin_ids)

    assert_instance_of RemoveAttachmentAndFolderJob, result
    assert_not_includes RecycleBin.all.pluck(:id), [1, 2, 3, 4, 5, 6, 7]
  end

  test "获取回收文件列表" do
    result = FileService::RecycleService.get_recycled user_id: @user.id
    # result = Folder.get_recycled @user.id
    pp result
  end
end
