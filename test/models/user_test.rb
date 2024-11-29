require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:user1)
  end

  test "the truth" do

<<<<<<< HEAD
<<<<<<< HEAD
    assert true
=======
    p User.get_free_space @user1.id
>>>>>>> 添加回收站功能
=======
    p User.get_free_space @user1.id
>>>>>>> 添加回收站功能
  end
end
