module OperateToken

  module Constants
    ALGORITHM = 'HS256'.freeze
    JWT_SECRET = Rails.application.credentials.dig(:JWT_SECRET)
    EXPIRATION_TIME = 7.days.from_now.to_i
  end

  class << self

    def generate_token(user_id)
      payload = {
        user_id: user_id,
        exp: Constants::EXPIRATION_TIME, # 过期时间
        iat: Time.now.to_i # 签发时间
      }
      JWT.encode(payload, Constants::JWT_SECRET, Constants::ALGORITHM)
    end

    def decode_token(token)
      decoded_token = JWT.decode(token, Constants::JWT_SECRET, true, algorithm: Constants::ALGORITHM)

      payload = decoded_token.first
      # 检查 token 是否过期
      if payload['exp'] < Time.now.to_i
        Rails.cache.delete_multi token
        Rails.cache.delete_multi payload["user_id"]
        nil
      else

        decoded_token
      end
    rescue JWT::DecodeError => e
      p "解码错误: #{e.message}"
      nil
    end

  end

end
