require "test_helper"

class FolderTest < ActiveSupport::TestCase

  setup do
    @user = users(:user1)
  end

  test "创建文件夹" do
    parent = folders(:root1)
    result = Folder.create_folder(@user, parent.numbering, 'test_create')
    # p parent.children.pluck(:numbering)
    # p result[:numbering]
    assert_includes parent.children.pluck(:numbering), result[:numbering]
  end
end
