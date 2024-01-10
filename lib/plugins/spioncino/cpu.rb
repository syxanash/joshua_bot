class Cpu < AbsPlugin
  def command
    /^\/cpu$/
  end

  def examples
    [
      { command: '/cpu', description: 'get some stats about the Bot\'s CPU' }
    ]
  end

  def do_stuff(_match_results)
    output = "My CPU temperature is currently: #{`vcgencmd measure_temp | grep  -o -E '[[:digit:]].*'`}"
    bot.api.send_message(chat_id: message.chat.id, text: output)
  end
end
