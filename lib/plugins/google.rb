class Google < Plugin
  def command
    /\/google (.+) for (.+?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want to use this command type:\n/google *something* for *someone*")
  end

  def do_stuff(match_results)

    stuff = match_results[1]
    user = match_results[2]

    bot.api.sendMessage(chat_id: message.chat.id, text: "#{user}: http://lmgtfy.com/?q=#{stuff}")
  end
end
