# because of "say" utility this plugin only works on OSX
# also you have to install opusenc tool in order to send ogg files

class Say < Plugin
  def command
    /^\/say ([a-zA-Z0-9\s|éèùòàì|\?\!|\'|\,|\:|\.|\"|\;]*?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "you can let me talk by typing:\n/say *dirty sentence you want me to read*")
  end

  def do_stuff(match_results)
    sentence_input = match_results[1]

    sentence = sentence_input

    sentence.gsub!("'", %q{\\\'})
    sentence.gsub!('"', %q{\\\"})

    if sentence.size < 140
      temp_name = "#{Time.now.to_i}"

      system("say -v Zarvox #{sentence} -o #{temp_name}raw_audio.ogg")
      system("opusenc #{temp_name}raw_audio.ogg #{temp_name}_audio.ogg")
      bot.api.sendAudio(chat_id: message.chat.id, audio: File.new("#{temp_name}_audio.ogg"))
      File.delete("#{temp_name}raw_audio.ogg","#{temp_name}_audio.ogg")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Sorry, my brain can't compute more than 140 characters 😅")
    end
  end
end
