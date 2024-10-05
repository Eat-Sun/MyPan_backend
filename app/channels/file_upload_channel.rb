class FileUploadChannel < ApplicationCable::Channel

  def subscribed
    decoded_token = OperateToken.decode_token params[:token]

    if decoded_token
      payload = decoded_token[0]

      stream_from "messages_channel_#{payload["user_id"]}"
    else

      reject
    end

  end

  #接收文件分片
  def receive data
    uid = data['uid']
    file_name = data['name']
    chunk_index = data['chunkIndex']
    chunk = data['chunk'] #经过了base64编码

    save_chunk uid, file_name, chunk_index, chunk
  end

  #保存分片
  def save_chunk uid, file_name, chunk_index, chunk
    directory = Rails.root.join('tmp', 'chunks', uid.to_s) #拼接路径
    FileUtils.mkdir_p(directory) #创建文件夹

    #写入分片
    file_path = directory.join("#{file_name}.part#{chunk_index}")
    File.open(file_path, 'wb') { |f| f.write(Base64.decode64(chunk)) }
  end

  #合并文件分片
  def merge_chunks data
    last_chunk = data['last_chunk']
    uploadParams = data['uploadParams']

    directory = Rails.root.join('tmp', 'chunks', last_chunk['uid'].to_s)
    file_path = Rails.root.join('tmp', 'files', last_chunk['name']) # 最终合并文件的路径

    FileUtils.mkdir_p(Rails.root.join('tmp', 'files'))

    retries = 0
    begin
      sleep 2
      File.open(file_path, 'wb') do |final_file|
        (1..last_chunk['totalChunks']).each do |chunk_index|
          part_file_path = directory.join("#{last_chunk['name']}.part#{chunk_index}")

          File.open(part_file_path, 'rb') do |part_file|
            final_file.write(part_file.read)
          end
        end
      end

      # 合并完成后，清理分片文件
      FileUtils.rm_rf(directory)
      upload uploadParams['token'], uploadParams['parent_folder_id'], file_path, last_chunk['totalSize'], uploadParams['file_type']
    rescue => e
      retries += 1

      if retries < 5
        sleep 2
        retry
      else
        raise e.message
      end
    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  #调用jobs上传文件
  private
    def upload token, parent_folder_id, file_path, file_size, file_type
      user_id = Rails.cache.read token
      file_type = 'undefined' if file_type == ""
      parent_folder = Folder.find parent_folder_id
      file_name = File.basename(file_path, ".*")
      b2_key = SecureRandom.alphanumeric(6)

      UploadToB2Job.perform_later user_id, file_path.to_s, b2_key

      attachment = Attachment.update_of_upload_for_database user_id, parent_folder, file_size, file_name, b2_key, file_type
      # p "attachment", attachment

      if attachment
        ActionCable.server.broadcast "messages_channel_#{user_id}", { type: 'finish', data: attachment }
      end

    end

end
