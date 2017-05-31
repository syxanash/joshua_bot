class Inputter < Plugin
  def initialize
    @values = %w(🗿 📄 ✂️)

    @choosen = nil
  end

  def command
    /^\/inputter$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "some test move along")
  end

  def do_stuff(match_results)
    answers =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [@values], one_time_keyboard: true)

    bot.api.send_message(chat_id: message.chat.id, text: "on my mark choose 🗿 📄 ✂️, ready?")
    sleep(4)
    bot.api.send_message(chat_id: message.chat.id, text: "go!", reply_markup: answers)

    @choosen = @values[Random.rand(@values.size)]

    MUST_REPLY
  end

  def do_answer(answer)
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: @choosen, reply_markup: kb)

    STOP_REPLYING
  end
end
