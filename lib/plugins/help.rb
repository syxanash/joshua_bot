class Help < AbsPlugin
  def command
    /\/help$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'type /help to see commands list')
  end

  def do_stuff(match_results)

    text_to_show = "You can give me the following commands:\n\n"
    plugin_classes = AbsPlugin.descendants

    plugin_classes.each do |plugin_name|
      text_to_show += "/#{plugin_name.to_s.downcase}\n"
    end

    text_to_show += "\nc'mon I'm all ears! 🔊👂"

    bot.api.sendMessage(chat_id: message.chat.id, text: text_to_show)
  end
end
