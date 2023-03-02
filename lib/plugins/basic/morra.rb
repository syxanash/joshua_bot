class Morra < AbsPlugin
  def command
    /^\/morra$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: 'play some rock paper scissors with /morra command!')
  end

  def do_stuff(_match_results)
    game_values = %w[🗿 📄 ✂️]
    bot_choice = game_values[Random.rand(game_values.size)]
    winner_message = 'no winners 😞'
    win_rules = [['📄', '🗿'], ['🗿', '✂️'], ['✂️', '📄']]
    answers_layout =
      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: [game_values.map { |item| { text: item } }], one_time_keyboard: true
      )

    bot.api.send_message(chat_id: message.chat.id, text: 'on my mark choose 🗿 📄 ✂️, ready?')
    sleep(2)
    bot.api.send_message(chat_id: message.chat.id, text: 'go!', reply_markup: answers_layout)

    human_choice = read_buffer

    until game_values.include? human_choice
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Enter a valid choice: #{game_values.join(' ')}",
        reply_markup: answers_layout
      )

      human_choice = read_buffer
    end

    win_rules.each do |rule|
      if rule[0] == bot_choice && rule[1] == human_choice
        winner_message = 'the machine wins! 🤖'
      elsif rule[1] == bot_choice && rule[0] == human_choice
        winner_message = 'filthy human beings...'
      end
    end

    remove_template = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(
      chat_id: message.chat.id,
      text: "I choose #{bot_choice}, #{winner_message}",
      reply_markup: remove_template
    )
  end
end
