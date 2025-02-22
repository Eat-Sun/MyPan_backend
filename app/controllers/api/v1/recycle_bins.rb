module Api
  module V1
    class RecycleBins < Grape::API
      include Defualt

      resources :recycle_bins do
        desc "加入回收站"
        params do
          use :token_validater
          optional :folder_ids
          requires :attachment_ids
          requires :opt
        end
        post 'recycle' do
          user_id = User.get_user params[:token], req: "id"
          result = nil

          if user_id
            result = FileService::RecycleService.add_to_bins(
              user_id: user_id,
              folder_ids: params[:folder_ids],
              attachment_ids: params[:attachment_ids],
              opt: params[:opt]
            )
          end

          if result.is_a? Exception
            build_response(message: "错误", exception: result.message)
          elsif result
            build_response(code: 1, data: result, message: "已移入回收站")
          else
            build_response(code: -1, data: nil, message: "移入回收站失败")
          end
        end

        desc "恢复文件"
        params do
          use :token_validater
          requires :folders, allow_blank: true, type: Hash do
            requires :ids, type: { value: Array, message: "必须为数组" }
            requires :top_ids, type: { value: Array, message: "必须为数组" }
            requires :ancestry, type: { value: String, message: "必须为字符串" }
          end
          requires :attachments, allow_blank: true, type: Hash do
            requires :ids, type: { value: Array, message: "必须为数组" }
            requires :top_ids, type: { value: Array, message: "必须为数组" }
            requires :parent_id, type: { value: Integer, message: "必须为数字" }
          end
          requires :bin_ids, type: { value: Array, message: "必须为数组" }
        end
        post 'restore' do
          user_id = User.get_user params[:token], req: "id"

          if user_id
            result = FileService::RecycleService.restore(folders: params[:folders], attachments: params[:attachments], bin_ids: params[:bin_ids])
          end

          if result.is_a? Exception
            build_response(message: "错误", exception: result.message)
          elsif result
            build_response(code: 1, data: result, message: "已从回收站恢复")
          else
            build_response(code: -1, data: nil, message: "恢复失败")
          end
        end

        desc "彻底删除文件"
        params do
          requires :token, type: String
          optional :free_space, type: Integer
          optional :folder_ids, type: { value: Array, message: "必须为数组" }
          requires :attachment_ids, type: { value: Array, message: "必须为数组" }
          requires :bin_ids, type: { value: Array, message: "必须为数组" }
        end
        post 'deleter' do
          p "param: #{params[:free_space]}"
          user = User.get_user(params[:token], req: 'user')
          result = FileService::RecycleService.remove(user: user, free_space: params[:free_space], folder_ids: params[:folder_ids], attachment_ids: params[:attachment_ids], bin_ids: params[:bin_ids])

          if result.is_a? Exception
            build_response(message: "错误", exception: result.message)
          elsif result
            build_response(code: 1, data: result, message: "删除成功")
          else
            build_response(code: -1, data: nil, message: "删除失败")
          end
        end

        desc "获取回收文件列表"
        params do
          use :token_validater
        end
        get 'getter' do
          user_id = User.get_user params[:token], req: "id"

          if user_id
            result = FileService::RecycleService.get_recycled user_id: user_id
          end

          if result.is_a? Exception
            build_response(message: "错误", exception: result.message)
          elsif result
            build_response(code: 1, data: result, message: "获取成功")
          else
            build_response(code: -1, data: nil, message: "获取失败")
          end
        end

      end
    end
  end
end
