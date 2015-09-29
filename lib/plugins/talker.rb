class Talker < Plugin
  def command
    /^\/talker\s(.*?)\s(.*?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "you can talk with the bot in a specific chat using:\n/talker *chatroom id* *sentence*\n😈 this is supposed to be a hidden feature available only for my maker!!!1")
  end

  def do_stuff(match_results)
    chatroom_id = match_results[1]
    sentence = match_results[2]

    if chatroom_id == "default"
      chatroom_id = message.chat.id
    end

    bot.api.sendMessage(chat_id: chatroom_id, text: sentence)
  end
end
