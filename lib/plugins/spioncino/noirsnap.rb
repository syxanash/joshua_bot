class NoirSnap < Plugin
  def command
    /(^\/noirsnap$|photo)/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "type /noirsnap")
  end

  def do_stuff(match_results)
    temp_name = "#{Time.now.to_i}_spy.jpg"
    
    begin
      system("python other/util_scripts/camera_script.py")
      bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('temp_photo.jpg', 'image/jpeg'))
    
      File.delete 'temp_photo.jpg'
    rescue
      bot.api.sendMessage(chat_id: message.chat.id, text: "fuck this shit man!")
    end
   
  end
end