class UploadToB2Job < ApplicationJob
  queue_as :file_operation

  def perform(user_id, file_path, b2_key, attachment)
    file = File.open(file_path)
    file_name = File.basename(file_path)
    file_path = Pathname.new file_path

    begin
      obj = S3_Resource.bucket(Conf::BUCKETNAME[:My_Pan]).object(b2_key)
      progress = Proc.new do |bytes, totals|
        progress_percentage = (100.0 * bytes.sum / totals.sum).round(2)
        if(progress_percentage < 100.0)
          ActionCable.server.broadcast "messages_channel_#{ user_id }", { type: 'processing', data: { b2_key: b2_key, name: file_name, size: totals.sum, percentage: progress_percentage } }
        else
          ActionCable.server.broadcast "messages_channel_#{user_id}", { type: 'finish', data: attachment }
        end
      end

      obj.upload_file(file, progress_callback: progress)
    rescue => e
      raise e
    ensure
      file.close if file
    end

  end
end
