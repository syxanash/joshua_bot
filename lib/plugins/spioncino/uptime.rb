class Uptime < Plugin
    def command
      /^\/uptime$/
    end
  
    def do_stuff(match_results)
      output = "⏱ my brain has been running for:\n#{`/usr/bin/uptime`}"
      bot.api.send_message(chat_id: message.chat.id, text: output)
    end
end