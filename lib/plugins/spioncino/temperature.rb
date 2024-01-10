class Temperature < AbsPlugin
  def command
    /^\/temperature$/
  end

  def examples
    [
      { command: '/temperature', description: 'get the temperature of the room' }
    ]
  end

  def do_stuff(_match_results)
    bot.api.send_message(chat_id: message.chat.id, text: `python utils/temperature.py`)
  end
end
