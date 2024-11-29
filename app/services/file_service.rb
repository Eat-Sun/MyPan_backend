module FileService
  def self.get_filelist_from_backblaze user
    begin
      folders = Folder.where(user: user, in_bins: false)
        .pluck("id, folder_name, numbering, ancestry")
        .map do |folder|
          {
            id: folder[0],
            type: 'folder',
            name: folder[1],
            numbering: folder[2],
            ancestry: folder[3],
            children: []
          }
        end
      attachments = Attachment.where(folder_id: folders.map { |folder| folder[:id] }, in_bins: false)
        .pluck("id, folder_id, file_type, file_name, b2_key, byte_size, file_monitor_id")
        .map do |attachment|
          {
            id: attachment[0],
            folder_id: attachment[1],
            type: attachment[2],
            name: attachment[3],
            b2_key: attachment[4],
            size: attachment[5]
          }
        end

      return [folders, attachments]
    rescue => e

      return e
    end
  end
end
