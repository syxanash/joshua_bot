class Intip < AbsPlugin
  def command
    /^\/intip$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "type:\n/intip to get internal IP on your network")
  end

  def examples
    [
      { command: '/intip', description: 'get the internal IP address' }
    ]
  end

  def do_stuff(_match_results)
    bot.api.send_message(chat_id: message.chat.id, text: "internal IP is: #{`hostname -I | awk '{print $1}'`}")
  end
end
