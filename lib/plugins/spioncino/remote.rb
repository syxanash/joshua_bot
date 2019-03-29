class Remote < AbsPlugin
  def initialize
    @main_reply = {:confirm => '', :action => ''}

    @options = {
      'stop bot' => Proc.new { Kernel.exit }, 
      'restart system' => Proc.new { system('sudo reboot') },
      'poweroff system' => Proc.new { system('sudo poweroff') }
    }
  end

  def command
    /^\/remote$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'do some system related things!')
  end

  def do_stuff(match_results)

    reply_keyboard =
        Telegram::Bot::Types::ReplyKeyboardMarkup
        .new(keyboard: @options.keys, one_time_keyboard: true)

    bot.api.send_message(chat_id: message.chat.id, text: 'what would you like to do?', reply_markup: reply_keyboard)

    MUST_REPLY
  end

  def do_answer(answer)
    no_keyboard = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    # check whether the input entered by the user is a confirmation
    # reply or an action to perform
    if answer == 'yes' || answer == 'no'
      @main_reply[:confirm] = answer
    else
      @main_reply[:action] = answer
    end

    # check if the confirmation reply is empty if true ask the user
    # if he wants to confirm the action he previously selected
    if @main_reply[:confirm].empty?
      reply_keyboard =
          Telegram::Bot::Types::ReplyKeyboardMarkup
          .new(keyboard: ['yes', 'no'], one_time_keyboard: true)

      bot.api.send_message(chat_id: message.chat.id, text: "you sure you want to #{answer}?", reply_markup: reply_keyboard)
    end

    if @main_reply[:confirm] == 'no'
      bot.api.send_message(chat_id: message.chat.id, text: "I won't do anything!", reply_markup: no_keyboard)

      STOP_REPLYING
    elsif @main_reply[:confirm] == 'yes'
      # check if the action selected by the user is actually contained in the
      # list of allowed actionss and execute the code block stored in hash

      if @options.keys.include? @main_reply[:action]
        bot.api.send_message(chat_id: message.chat.id, text: "I'm going to #{@main_reply[:action]}", reply_markup: no_keyboard)
      
        @options[@main_reply[:action]].call
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Can't recognize the command!", reply_markup: no_keyboard)
      end

      STOP_REPLYING
    end
  end
end