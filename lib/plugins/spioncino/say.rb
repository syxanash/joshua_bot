class Say < AbsPlugin
  def command
    /^\/say ([a-zA-Z0-9\s|éèùòàì|\?\!|\'|\,|\:|\.|\"|\;]*?)$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "you can let me talk by typing:\n/say [sentence you'd like me to read]")
  end

  def do_stuff(match_results)
    sentence = match_results[1]

    sentence.gsub!('"', %q{\\\"})

    if sentence.size < 140
      temp_name = "#{BotConfig.config['temp_directory']}/#{Time.now.to_i}"

      system("espeak -s 120 \"#{sentence}\" --stdout > #{temp_name}first_audio.wav")
      system("opusenc #{temp_name}first_audio.wav #{temp_name}_audio.ogg")

      bot.api.sendAudio(chat_id: message.chat.id, audio: Faraday::UploadIO.new("#{temp_name}_audio.ogg", 'ogg/vorbis'))

      File.delete("#{temp_name}first_audio.wav", "#{temp_name}_audio.ogg")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry, my brain can't compute more than 140 characters 😅")
    end
  end
end
