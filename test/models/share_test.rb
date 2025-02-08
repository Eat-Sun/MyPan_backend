require "test_helper"

class ShareTest < ActiveSupport::TestCase

  setup do
    @user1 = users(:user1)
    @user2 = users(:user2)
    @share = shares(:share1)

  end

  test "分享文件" do
    share = Share.create!(user: @user1, link: "qwnoignqwg", varify: 1234)
    folder_opts = [
      { folder_id: 11, share_id: share.id, top: true },
      { folder_id: 111, share_id: share.id, top: false },
    ]
    attachment_opts = [
      { attachment_id: 11, share_id: share.id, top: true },
      { attachment_id: 111, share_id: share.id, top: false },
      { attachment_id: 112, share_id: share.id, top: false },
      { attachment_id: 1111, share_id: share.id, top: false },
      { attachment_id: 1112, share_id: share.id, top: false }
    ]

    result = Share.share_to_others share, folder_opts, attachment_opts

    assert_kind_of Hash, result
  end

  test "获取分享文件" do
    folders, attachments = Share.accept_from_others @user2.id, @share.link, @share.varify
    # p folders.backtrace
    expected_folders = [
      {
        :id=>232,
        :type=>"folder",
        :name=>"Folder1_1",
        :numbering=>"1_brni",
        :ancestry=>"2_dqfq",
        :children=>[]
      },
      {
        :id=>233,
        :type=>"folder",
        :name=>"Folder1_1_sub2",
        :numbering=>"1_rwvh",
        :ancestry=>"1_brni",
        :children=>[]
      },
      {
        :id=>234,
        :type=>"folder",
        :name=>"Folder1_1_sub1",
        :numbering=>"1_yptc",
        :ancestry=>"1_brni",
        :children=>[]
      }
    ]
    expected_attachments = [
      {
        :id=>2219,
        :folder_id=>2,
        :type=>"picture",
        :name=>"att1_1",
        :b2_key=>"wvWE20",
        :byte_size=>"186154"
      },
      {
        :id=>2220,
        :folder_id=>2,
        :type=>"word",
        :name=>"att1_2",
        :b2_key=>"dwaW3B",
        :byte_size=>"19861654"
      },
      {
        :id=>2213,
        :folder_id=>232,
        :type=>"undefined",
        :name=>"att11_1",
        :b2_key=>"fG56hI",
        :byte_size=>"51200"
      },
      {
        :id=>2214,
        :folder_id=>232,
        :type=>"picture",
        :name=>"att11_2",
        :b2_key=>"jK78lM",
        :byte_size=>"307200"
      },
      {
        :id=>2215,
        :folder_id=>233,
        :type=>"undefined",
        :name=>"att112_1",
        :b2_key=>"Ag3Wg1",
        :byte_size=>"189641"
      },
      {
        :id=>2216,
        :folder_id=>233,
        :type=>"word",
        :name=>"att112_2",
        :b2_key=>"zB56dE",
        :byte_size=>"168198"
      },
      {
        :id=>2217,
        :folder_id=>234,
        :type=>"undefined",
        :name=>"att111_1",
        :b2_key=>"vW34xY",
        :byte_size=>"256000"
      },
      {
        :id=>2218,
        :folder_id=>234,
        :type=>"word",
        :name=>"att111_2",
        :b2_key=>"zA56bC",
        :byte_size=>"768000"
      }
    ]

    assert_equal expected_folders, folders
    assert_equal expected_attachments, attachments
    # assert_equal [2, 2, 2, 2, 2, 2, 2, 2], owner_counts
  end

  test "获取用户已分享" do
    shared_attachments = Share.get_shares users(:user1)

    shared_attachments.each do |item|
      assert_kind_of Hash, item
    end
  end

  test "取消分享" do
    result = Share.cancel_shares(@share.link)
    folder_count = ActiveRecord::Base.connection.execute("select * from folders_shares where share_id = 1").count
    attachment_count = ActiveRecord::Base.connection.execute("select * from attachments_shares where share_id = 1").count

    # p folder_count
    assert(result)
    assert_raises(ActiveRecord::RecordNotFound){ @share.reload }
    assert_equal(folder_count, 0, "分享链接删除后，中间表的分享文件也应该为空")
    assert_equal(attachment_count, 0, "分享链接删除后，中间表的分享文件也应该为空")
  end

end
