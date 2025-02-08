# frozen_string_literal: true

module Api
  module V1
    class Sessions < Grape::API
      include Defualt

      resources :sessions do
        desc '登陆'
        params do
          requires :user, type: Hash do
            requires :username, allow_blank: true, desc: '用户名'
            requires :password, allow_blank: true, desc: '密码'
          end
          optional :token
        end
        post 'create' do
          user = User.authenticate(params[:user][:username], params[:user][:password])
          token = nil

          if user
            user_data = {
              form_data: FileService.get_filelist_from_db(user),
              free_space: User.get_free_space(user.id)
            }

            if params[:token].present?
              decoded_token = OperateToken.decode_token params[:token]
              # 检查解码结果是否有效
              if decoded_token
                token_payload = decoded_token.first
                if user.id == token_payload['user_id']
                  # 用户与token匹配，使用现有token
                  token = params[:token]
                else
                  # 用户与token不匹配，另一个用户在客户端上登陆
                  Rails.cache.delete params[:token]
                  token = OperateToken.generate_token(user.id)
                end
              else
                # Token 解码失败或者过期，生成新的 token
                token = OperateToken.generate_token(user.id)
              end
            else
              # 没有传递 token，生成新的 token
              token = OperateToken.generate_token(user.id)
            end
            Rails.cache.write token, user.id

            build_response(code: 1, data: { token: token, user_data: user_data}, message: '登陆成功')
          else
            build_response(code: -1, message: '用户名或密码错误')
          end
        end

        desc '退出登陆'
        params do
          use :token_validater
          requires :userData, type: JSON do
            requires :form_data, { type: Array, message: '文件数据缺失' }
            requires :free_space, { type: Integer, message: '剩余空间缺失' }
          end
        end
        post 'quit' do
          begin
            user_id = Rails.cache.read params[:token]

            if user_id
              Rails.cache.write params[:token], user_id
              Rails.cache.write user_id, params[:userData]
              p params[:userData]
              status 200
            end

          rescue => e
            p e.message
          end

        end

      end


    end
  end
end
