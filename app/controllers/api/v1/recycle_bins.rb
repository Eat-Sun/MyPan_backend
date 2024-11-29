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
          requires :mixed, type: { value: Array, message: "必须为数组" }
        end
        post 'recycle' do
          user_id = User.get_user params[:token]
          if user_id
            user = User.find user_id
            result = RecycleBin.add_to_bins user, params[:folder_ids], params[:attachment_ids], params[:mixed]
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
          optional :folder_ids, type: { value: Array, message: "必须为数组" }
          requires :attachment_ids, type: { value: Array, message: "必须为数组" }
          requires :bin_ids, type: :Array
        end
        post 'restore' do
          result = RecycleBin.restore params[:folder_ids], params[:attachment_ids], params[:bin_ids]

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
          optional :folder_ids, type: { value: Array, message: "必须为数组" }
          requires :attachment_ids, type: { value: Array, message: "必须为数组" }
          requires :bin_ids, type: :Array
        end
        post 'deleter' do
          result = RecycleBin.remove params[:folder_ids], params[:attachment_ids], params[:bin_ids]

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
          user_id = User.get_user params[:token]

          if user_id
            result = RecycleBin.get_recycled user_id
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
