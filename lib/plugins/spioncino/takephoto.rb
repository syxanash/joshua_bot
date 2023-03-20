class TakePhoto < AbsPlugin
  def command
    /^\/takephoto$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: 'type /takephoto')
  end

  def examples
    [
      { command: '/takephoto', description: 'take a photo of the room using the camera' }
    ]
  end

  def do_stuff(_match_results)
    bot.api.sendChatAction(chat_id: message.chat.id, action: 'upload_photo')

    picture_file_name = "#{BotConfig.config['temp_directory']}/temp_photo.jpg"

    system("raspistill -o #{picture_file_name} -w 2592 -h 1944")
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new(picture_file_name, 'image/jpeg'))

    File.delete picture_file_name
  rescue
    bot.api.send_message(chat_id: message.chat.id, text: 'Something went wrong while taking the picture!')
  end
end
