class TakePhoto < AbsPlugin
  def command
    /(^\/takephoto$|photo)/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: 'type /takephoto')
  end

  def do_stuff(_match_results)
    begin
      system('raspistill -o temp_photo.jpg -w 2592 -h 1944')
      bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_photo.jpg', 'image/jpeg'))

      File.delete 'temp_photo.jpg'
    rescue
      bot.api.send_message(chat_id: message.chat.id, text: 'Something went wrong while taking the picture!')
    end
  end
end
