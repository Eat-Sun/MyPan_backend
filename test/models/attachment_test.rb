require "test_helper"

class AttachmentTest < ActiveSupport::TestCase

  setup do
    @user = users(:user1)
  end
  test "获取用户文件信息" do
    # result = Attachment.get_filelist_from_backblaze(@user)
    # p result[1]
    attachments(:att1_1).send(:plus_file_monitor)


    # assert_equal expected, result
  end


end
