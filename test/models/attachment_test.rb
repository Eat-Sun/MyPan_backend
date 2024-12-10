require "test_helper"

class AttachmentTest < ActiveSupport::TestCase

  setup do
    @user = users(:user1)
  end
  test "获取用户文件信息" do
    result = FileService.get_filelist_from_db(@user)
    puts result.to_json
    attachments(:att1_1).send(:plus_file_monitor)


    # assert_equal expected, result
  end

  test "下载" do
    key_and_names = {"0"=>{"key"=>"dFbF2Z", "name"=>"user.rb"}}

    result = Attachment.download_from_blackblaze key_and_names

    p result
  end


end
