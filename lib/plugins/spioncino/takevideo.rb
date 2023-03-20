class TakeVideo < AbsPlugin
  def command
    /^\/takevideo$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: 'type /takevideo')
  end

  def examples
    [
      { command: '/takevideo', description: 'take a video of the room using the camera' }
    ]
  end

  def do_stuff(_match_results)
    temp_name = "#{Time.now.to_i}_spy_video"

    bot.api.sendChatAction(chat_id: message.chat.id, action: 'upload_video')

    system("raspivid -o #{temp_name}.h264 -w 1280 -h 720 -t 10000")
    system("MP4Box -add #{temp_name}.h264 #{temp_name}.mp4")

    bot.api.sendVideo(chat_id: message.chat.id, video: Faraday::UploadIO.new(temp_name + '.mp4', 'video/mp4'))

    File.delete(temp_name + '.h264', temp_name + '.mp4')
  end
end
