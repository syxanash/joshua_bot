class Morra < Plugin
  def command
    /^\/morra$/
  end

  def do_stuff(match_results)
    values = %w(🗿 📄 ✂️)

    answers =
      Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [values], one_time_keyboard: true)

    bot.api.send_message(chat_id: message.chat.id, text: "on my mark choose 🗿 📄 ✂️, ready?")
    sleep(2)
    bot.api.send_message(chat_id: message.chat.id, text: "go!", reply_markup: answers)
    sleep(3)

    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: values[Random.rand(values.size)], reply_markup: kb)
  end
end
