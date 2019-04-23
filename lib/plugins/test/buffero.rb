require 'JSON'

class Buffero < AbsPlugin
  def command
    /\/buffero$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: '/buffero')
  end

  def do_stuff(match_results)
    bot.api.sendMessage(chat_id: message.chat.id, text: 'Enter first number: ')
    first = read_buffer
    bot.api.sendMessage(chat_id: message.chat.id, text: 'Enter second number: ')
    second = read_buffer

    bot.api.sendMessage(chat_id: message.chat.id, text: "Result is #{first.to_i + second.to_i}")
  end
end
