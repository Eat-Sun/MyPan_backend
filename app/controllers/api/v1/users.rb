# frozen_string_literal: true

module Api
  module V1
    class Users < Grape::API
      CAPTCHA = 'a(zB$x8(3F'
      include Defualt

      helpers do
        def user_params
          params[:user]&.slice(:username, :email, :password, :password_confirmation)
        end
      end

      namespace :users do
        desc '创建用户'
        params do
          requires :user, type: Hash do
            requires :username, type: String
            requires :email, type: String
            requires :phone, type: String
            requires :password, type: String
            requires :password_confirmation, type: String
            requires :captcha, type: String
          end
        end
        post 'create' do
          captcha = params[:user][:captcha]
          error!(build_response(code: -1, data: nil, message: '验证码错误'), 200) if captcha&.blank? || captcha != CAPTCHA

          user = User.new(user_params)

          if user.save
            build_response(code: 1, message: '注册成功')
          else
            error_messages = user.errors.full_messages.join(', ')
            error!(error_messages, 422)
          end
        end

        desc '获取验证码'
        params do
          requires :phone, type: String
        end
        post 'verifycode' do
          phone = params[:phone]
          verify_code = LuosimaoSmsSender.generate_verify_code
          sender = LuosimaoSmsSender.new(phone, verify_code)

          result = sender.send

          if result.parsed_response['error'].to_i.zero?
            build_response(code: 1, data: nil, message: 'success')
          else
            build_response(code: -1, data: nil, message: 'error')
          end
        end
      end
    end
  end
end
