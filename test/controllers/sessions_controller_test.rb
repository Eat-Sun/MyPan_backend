require "test_helper"
require 'active_support'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "分享及获取" do
    token = OperateToken.generate_token(1)
    data = [
      {
        "id"=>11,
        "type"=>"folder",
        "name"=>"Folder1_1",
        "children"=>[
          {
            "id"=>111,
            "type"=>"folder",
            "name"=>"Folder1_1_sub1",
            "children"=>[
              {
                "id"=>1111,
                "type"=>"undefined",
                "name"=>"att111_1",
                "b2_key"=>"vW34xY",
                "size"=>"256000"
              },
              {
                "id"=>1112,
                "type"=>"word",
                "name"=>"att111_2",
                "b2_key"=>"zA56bC",
                "size"=>"768000"
              }
            ]
          },
          {
            "id"=>112,
            "type"=>"folder",
            "name"=>"Folder1_1_sub2",
            "children"=>[
              {
                "id"=>1121,
                "type"=>"undefined",
                "name"=>"att112_1",
                "b2_key"=>"Ag3Wg1",
                "size"=>"189641"
              },
              {
                "id"=>1122,
                "type"=>"word",
                "name"=>"att112_2",
                "b2_key"=>"zB56dE",
                "size"=>"168198"
              }
            ]
          },
          {
            "id"=>111,
            "type"=>"undefined",
            "name"=>"att11_1",
            "b2_key"=>"fG56hI",
            "size"=>"51200"
          },
          {
            "id"=>112,
            "type"=>"picture",
            "name"=>"att11_2",
            "b2_key"=>"jK78lM",
            "size"=>"307200"
          }
        ]
      },
      {
        "id"=>11,
        "type"=>"picture",
        "name"=>"att1_1",
        "b2_key"=>"wvWE20",
        "size"=>"186154"
      },
      {
        "id"=>12,
        "type"=>"word",
        "name"=>"att1_2",
        "b2_key"=>"dwaW3B",
        "size"=>"19861654"
      }
    ]
    top = [
      {
        "id"=>11,
        "type"=>"folder",
        "name"=>"Folder1_1"
      },
      {
        "id"=>11,
        "type"=>"picture",
        "name"=>"att1_1",
        "b2_key"=>"wvWE20",
        "size"=>"186154"
      },
      {
        "id"=>12,
        "type"=>"word",
        "name"=>"att1_2",
        "b2_key"=>"dwaW3B",
        "size"=>"19861654"
      }
    ]

    post "/api/v1/shares/new", params: {
      token: token,
      data: data,
      top: top,
      varify: 1234
    }

    assert_response :success
    xml_doc = Nokogiri::XML(@response.body)
    data_node = xml_doc.at_xpath('//data')

    share = data_node.at_xpath('share').content
    link = data_node.at_xpath('link').content
    varify = data_node.at_xpath('varify').content

    get "/api/v1/shares/getter", params: {
      token: token,
      share: share,
      link: link,
      varify: varify
    }
    assert_response :success


    # result = Hash.from_xml(Nokogiri::XML(@response.body).to_xml)["hash"]["data"]

    # assert_equal data, result
  end

  test "登陆及获取数据" do
    post "/api/v1/sessions/create", params: {
      user: {
        "username": "user1",
        "password": "123456"
      }
    }
  end
end
