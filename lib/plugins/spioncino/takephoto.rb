class TakePhoto < AbsPlugin
  def command
    /(^\/takephoto$|photo)/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "type /takephoto")
  end

  def do_stuff(match_results)
    begin
      system("python other/util_scripts/camera_script.py")
      bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_photo.jpg', 'image/jpeg'))

      File.delete 'temp_photo.jpg'
    rescue
      bot.api.send_message(chat_id: message.chat.id, text: "Something went wrong while taking the picture!")
    end
  end
end
