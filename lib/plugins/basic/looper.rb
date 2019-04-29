class Looper < AbsPlugin
  def command
    /^\/looper$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'play some rock paper scissors with /looper command!')
  end

  def do_stuff(match_results)
    my_var = read_buffer

    loop do
      puts "I'm looping"

      sleep(1)
    end
  end
end
