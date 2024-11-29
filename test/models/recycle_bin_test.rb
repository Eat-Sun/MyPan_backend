require "test_helper"

class RecycleBinTest < ActiveSupport::TestCase
  setup do
    @user = users(:user1)
    @folder_ids = [111, 112]
    @attachment_ids = [1111, 1112, 1121, 1122]
    @bin_ids = [1, 2, 3, 4]
    @mixed = [
      {
        mix_id: 111,
        type: 'folder',
        name: "Folder1_1_sub1",
        numbering: "1_yptc",
        b2_key: nil
      },
      {
        mix_id: 112,
        type: 'folder',
        name: "Folder1_1_sub2",
        numbering: '1_rwvh',
        b2_key: nil
      },
      {
        mix_id: 1111,
        type: 'undefined',
        name: "att111_1",
        numbering: '',
        b2_key: "vW34xY"
      },
      {
        mix_id: 1112,
        type: 'word',
        name: "att111_2",
        numbering: '',
        b2_key: "zA56bC"
      },
      {
        mix_id: 1121,
        type: 'undefined',
        name: "att112_1",
        numbering: '',
        b2_key: "Ag3Wg1"
      },
      {
        mix_id: 1122,
        type: 'word',
        name: "att112_2",
        numbering: '',
        b2_key: "zB56dE"
      }
    ]
  end
  test "添加到回收站" do
    result = RecycleBin.add_to_bins(@user, @folder_ids, @attachment_ids, @mixed)
    # p result
    # 验证数据库更新操作是否成功
    assert_equal true, result

    folders = Folder.where(id: @folder_ids).pluck(:id, :in_bins)
    attachments = Attachment.where(id: @attachment_ids).pluck(:id, :in_bins)
    # recycled = RecycleBin.all
    recycled = RecycleBin.select(:id, :mix_id, :type, :name, :b2_key, :updated_at).where(user_id: @user.id).to_json
    puts recycled

    folders.each { |folder| assert_equal true, folder[1], "Folder #{folder[0]} should be in bins" }
    attachments.each { |attachment| assert_equal true, attachment[1], "Attachment #{attachment[0]} should be in bins" }
  end

  test "恢复文件" do
    folder_ids = [111, 112]
    attachment_ids = [1111, 1112]
    RecycleBin.add_to_bins(@user, @folder_ids, @attachment_ids, @mixed)
    result = RecycleBin.restore(folder_ids, attachment_ids, @bin_ids)
    # 验证数据库更新操作是否成功
    assert result

    folders = Folder.where(id: folder_ids).pluck(:id, :in_bins)
    attachments = Attachment.where(id: attachment_ids).pluck(:id, :in_bins)

    folders.each { |folder| assert_equal false, folder[1], "Folder #{folder[0]} should be restored" }
    attachments.each { |attachment| assert_equal false, attachment[1], "Attachment #{attachment[0]} should be restored" }
  end

  test "彻底删除文件" do
    RecycleBin.add_to_bins(@user, @folder_ids, @attachment_ids, @mixed)
    result = RecycleBin.remove([111, 112], [1111, 1112], @bin_ids)

    assert_equal true, result
    assert_not_includes RecycleBin.select(:id).all.ids, [1, 2, 3, 4]
  end

  test "获取回收文件列表" do
    result = RecycleBin.get_recycled users(:user1).id
    assert true
    # p result
  end
end
