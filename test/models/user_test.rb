require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user1 = users(:user1)
  end

  test "the truth" do

    p User.get_free_space @user1.id
  end
end
