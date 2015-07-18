class Morra < Plugin
  def command
    '/morra'
  end

  def do_stuff(match_results)
    values = %w(🗿 📄 ✂️)

    answers =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [values], one_time_keyboard: true)

    bot.api.sendMessage(chat_id: message.chat.id, text: "on my mark choose 🗿 📄 ✂️, ready?")
    sleep(2)
    bot.api.sendMessage(chat_id: message.chat.id, text: "3")
    sleep(1)
    bot.api.sendMessage(chat_id: message.chat.id, text: "2")
    sleep(1)
    bot.api.sendMessage(chat_id: message.chat.id, text: "1")
    sleep(1)
    bot.api.sendMessage(chat_id: message.chat.id, text: "go!", reply_markup: answers)
    sleep(3)
    bot.api.sendMessage(chat_id: message.chat.id, text: values[Random.rand(values.size)])
  end
end
