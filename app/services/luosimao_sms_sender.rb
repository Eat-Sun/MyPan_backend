class LuosimaoSmsSender
  include HTTParty
  base_uri 'http://sms-api.luosimao.com/v1'

  def initialize(mobile, verify_code)
    @mobile = mobile
    @verify_code = verify_code
  end

  def send
    self.class.post('/send.json',
                    basic_auth: {
                      username: ENV['LUOSIMAO_API_KEY'] || 'api',
                      password: 'key-d35caebaf2b123a4b071ffbf612721ef'
                    },
                    body: {
                      mobile: @mobile,
                      message: "验证码：#{@verify_code}【铁壳测试】"
                    },
                    headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })
  end

  def self.generate_verify_code(length = 6)
    min = 10**(length - 1)
    max = 10**length - 1
    rand(min..max).to_s
  end
end
