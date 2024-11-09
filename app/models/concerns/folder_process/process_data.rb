module FolderProcess
  module ProcessData

    def process_data arranged_data
      arranged_data.map do |folder, children|
        {
          id: folder.id,
          type: "folder",
          name: folder.folder_name,
          children: process_data(children) + attached_files_info(folder.attachments)
        }
      end
    end

    def attached_files_info(filelist)
      filelist.map do |file|
        {
          id: file.id,
          type: file.file_type,
          name: file.file_name,
          b2_key: file.b2_key,
          size: file.byte_size
        }
      end
    end

  end
end
