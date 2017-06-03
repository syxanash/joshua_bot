class Morra < Plugin
  def initialize
    @values = %w(🗿 📄 ✂️)
  end

  def command
    /^\/morra$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'play some rock paper scissors with /morra command!')
  end

  def do_stuff(match_results)
    answers =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [@values], one_time_keyboard: true)

    bot.api.send_message(chat_id: message.chat.id, text: 'on my mark choose 🗿 📄 ✂️, ready?')
    sleep(2)
    bot.api.send_message(chat_id: message.chat.id, text: 'go!', reply_markup: answers)

    # if do stuff returns MUST_REPLY constant it means the plugin requires
    # further inputs from a user these inputs will be managed by do_answer method
    MUST_REPLY
  end

  def do_answer(answer)
    choosen = @values[Random.rand(@values.size)]

    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: "I choose #{choosen}", reply_markup: kb)

    # if do answer doesn't need new inputs return STOP_REPLYING constant
    # to make sure the next message sent by user won't be passed to do_answer
    STOP_REPLYING
  end
end
