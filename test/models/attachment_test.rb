require "test_helper"

class AttachmentTest < ActiveSupport::TestCase

  setup do
    @user = users(:user1)
  end
  test "获取用户文件信息" do
<<<<<<< HEAD
<<<<<<< HEAD
    # result = Attachment.get_filelist_from_backblaze(@user)
    # p result[1]
    attachments(:att1_1).send(:plus_file_monitor)
=======
    result = FileService.get_filelist_from_backblaze(@user)
    puts result.to_json
    # attachments(:att1_1).send(:plus_file_monitor)
>>>>>>> 添加回收站功能
=======
    result = FileService.get_filelist_from_backblaze(@user)
    puts result.to_json
    # attachments(:att1_1).send(:plus_file_monitor)
>>>>>>> 添加回收站功能


    # assert_equal expected, result
  end


end
