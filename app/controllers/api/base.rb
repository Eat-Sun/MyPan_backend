module Api
	class Base < Grape::API
		mount V1::Users
		mount V1::Sessions
		mount V1::Folders
		mount V1::Attachments
		mount V1::Shares
		mount V1::UserData
		mount V1::RecycleBins
	end
end
