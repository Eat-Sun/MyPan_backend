require "test_helper"

class ShareTest < ActiveSupport::TestCase
  fixtures :users, :folders, :attachments, :shares, :folders_shares, :attachments_shares, :file_monitors

  setup do
    @user = users(:user2)
    @share = shares(:share1)
  end

  test "分享文件" do

    assert true
  end

  test "获取分享文件" do
    processed = Share.accept_from_others @user, @share.link, @share.varify

    owner_counts = @share.attachments.map do |attachment|
      attachment.file_monitor.owner_count
    end

    expected = [
      {
        :id=>223,
        :type=>"folder",
        :name=>"Folder1_1",
        :children=>[
          {
            :id=>224,
            :type=>"folder",
            :name=>"Folder1_1_sub1",
            :children=>[
              {
                :id=>2217,
                :type=>"undefined",
                :name=>"att111_1",
                :b2_key=>"vW34xY",
                :size=>"256000"
              }
            ]
          },
          {
            :id=>225,
            :type=>"folder",
            :name=>"Folder1_1_sub2",
            :children=>[]
          },
          {
            :id=>2215,
            :type=>"undefined",
            :name=>"att11_1",
            :b2_key=>"fG56hI",
            :size=>"51200"
          },
          {
            :id=>2216,
            :type=>"picture",
            :name=>"att11_2",
            :b2_key=>"jK78lM",
            :size=>"307200"
          }
        ]
      },
      {
        :id=>2213,
        :type=>"picture",
        :name=>"att1_1",
        :b2_key=>"wvWE20",
        :size=>"186154"
      },
      {
        :id=>2214,
        :type=>"word",
        :name=>"att1_2",
        :b2_key=>"dwaW3B",
        :size=>"19861654"
      }
    ]

    assert_equal expected, processed
    assert_equal owner_counts, [2, 2, 2, 2, 2]
  end
end
