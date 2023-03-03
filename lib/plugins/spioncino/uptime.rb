class Uptime < AbsPlugin
  def command
    /^\/uptime$/
  end

  def do_stuff(_match_results)
    output = "⏱ my brain has been running for:\n#{`/usr/bin/uptime`}"
    bot.api.send_message(chat_id: message.chat.id, text: output)
  end
end
