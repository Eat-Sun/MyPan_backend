module Api
	class Base < Grape::API
		mount V1::Users
		mount V1::Sessions
		mount V1::Folders
		mount V1::Attachments
		mount V1::Shares
		mount V1::UserData

		# http_basic do | username, password|
		# 	username == 'test' and password == 'test password'
		# end

		add_swagger_documentation(
			info: {
				title: 'MyPan API Documentation',
				contact_email: 'service@localhost'
			},
			mount_path: '/doc/swagger',
			doc_version: '0.1.0'
		)
	end
end
