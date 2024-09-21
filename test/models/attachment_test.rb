require "test_helper"

class AttachmentTest < ActiveSupport::TestCase
  fixtures :users, :folders, :attachments

  setup do
    @user = User.create!(username: "Test User", email: "test@example.com", password: 123456, password_confirmation: 123456)
    @subfolder1 = Folder.find_by(user: @user, folder_name: "root").children.create!(user: @user, folder_name: "newFolder")
    @attachment1 = Folder.find_by(user: @user, folder_name: "root").attachments.create!(file_name: "OIP-C.jpeg", file_type: "picture", b2_key: "CEWtoh", byte_size: "23615")
    @attachment2 = @subfolder1.attachments.create!(file_name: "R-C.jpeg", file_type: "picture", b2_key: "wvWE20", byte_size: "455858")
  end
  test "the truth" do
    result = Attachment.get_filelist_from_backblaze(@user)

    p "result", result

    expected = [{
      "id": Folder.find_by(user: @user, folder_name: "root").id,
      "type": "folder",
      "name": "root",
      "children": [
        {
          "id": @subfolder1.id,
          "type": "folder",
          "name": "newFolder",
          "children": [
            {
              "id": @attachment2.id,
              "type": "picture",
              "name": "R-C.jpeg",
              "b2_key": "wvWE20",
              "size": "455858"
            }
          ]
        },
        {
          "id": @attachment1.id,
          "type": "picture",
          "name": "OIP-C.jpeg",
          "b2_key": "CEWtoh",
          "size": "23615"
        }
      ]
    }]

    assert_equal expected, result
  end


end
