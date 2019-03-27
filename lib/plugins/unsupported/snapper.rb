class Snapper < Plugin
  def command
    /^\/snapper?$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "type /snapper")
  end

  def do_stuff(match_results)
    stealth = match_results[1]

    system("mpg123 other/media/alert.mp3")
    
    temp_name = "#{Time.now.to_i}_spy.jpg"
    
    2.times do |i|
      system("fswebcam --save #{temp_name} -d /dev/video#{i} --skip 30 -r 640x480")
      bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new(temp_name, 'image/jpeg'))
    end

    File.delete(temp_name)
  end
end
