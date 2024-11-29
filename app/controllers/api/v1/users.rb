module Api
	module V1
		class Users < Grape::API
			include Defualt

			helpers do
        def user_params
        	params[:user]&.slice(:username, :email, :password, :password_confirmation) if params[ :user]
        end
		  end

			resources :users do

				desc "创建用户"
				post 'create' do
				  user = User.new(user_params)

				  if user.save
				    build_response( code: 1, message: "注册成功")
				  else
				    error_messages = user.errors.full_messages.join(", ")
    				error!(error_messages, 422)
				  end

				end

			end

		end
	end
end
