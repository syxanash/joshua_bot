class Temperature < AbsPlugin
  def command
    /^\/temperature$/
  end

  def examples
    [
      { command: '/temperature', description: 'get the temperature of the CPU' }
    ]
  end

  def do_stuff(_match_results)
    output = "My CPU temperature is currently: #{`vcgencmd measure_temp | grep  -o -E '[[:digit:]].*'`}"
    bot.api.send_message(chat_id: message.chat.id, text: output)
  end
end
