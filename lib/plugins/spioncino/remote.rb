class Remote < AbsPlugin
  def command
    /^\/remote$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'do some system related things!')
  end

  def do_stuff(match_results)
    commands_map = {
      'stop bot' => Proc.new { Kernel.exit }, 
      'restart system' => Proc.new { system('sudo reboot') },
      'poweroff system' => Proc.new { system('sudo poweroff') }
    }

    reply_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: commands_map.keys,
      one_time_keyboard: true
    )
    confirm_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: %w[yes no],
      one_time_keyboard: true
    )
    no_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    bot.api.send_message(chat_id: message.chat.id, text: 'what would you like to do?', reply_markup: reply_keyboard)
    human_choice = read_buffer

    if commands_map.keys.include? human_choice
      bot.api.send_message(chat_id: message.chat.id, text: "you sure you want to #{human_choice}?", reply_markup: confirm_keyboard)
      confirm_reply = read_buffer

      if confirm_reply == 'no'
        bot.api.send_message(chat_id: message.chat.id, text: "I won't do anything!", reply_markup: no_keyboard)
      elsif confirm_reply == 'yes'
        bot.api.send_message(chat_id: message.chat.id, text: "I'm going to #{human_choice}", reply_markup: no_keyboard)
        
        commands_map[human_choice].call
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Enter valid option", reply_markup: no_keyboard)
      end
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Can't recognize the command!", reply_markup: no_keyboard)
    end
  end
end