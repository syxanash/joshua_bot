# to use this plugin you need fortune program on your OS
# type: "brew install fortune" to install on OSX

class Fortune < Plugin
  def command
    '/fortune'
  end

  def do_stuff(match_results)
    fortune = "🍪📜🍪\n#{`fortune`}"
    bot.api.sendMessage(chat_id: message.chat.id, text: fortune)
  end
end
