# to use this plugin you need fortune program on your OS
# type: "brew install fortune" to install on macOS

class Fortune < AbsPlugin
  def command
    /^\/fortune$/
  end

  def do_stuff(match_results)
    fortune = "🍪📜🍪\n#{`fortune`}"
    bot.api.send_message(chat_id: message.chat.id, text: fortune)
  end
end
