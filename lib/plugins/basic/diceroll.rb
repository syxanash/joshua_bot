class DiceRoll < AbsPlugin
  def command
    /^\/diceroll\s?(\d*?)?$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "you can roll a dice with:\n/diceroll [number of faces] (default 6)")
  end

  def examples
    [
      { command: '/diceroll',    description: 'return a random number from 1 to 6' },
      { command: '/diceroll 10', description: 'return a random number from 1 to 10' }
    ]
  end

  def do_stuff(match_results)
    dice_max_value = match_results[1]

    max_value = dice_max_value.empty? ? 6 : dice_max_value.to_i
    dice_value = Random.rand(1..max_value)

    bot.api.send_message(chat_id: message.chat.id, text: dice_value)
  end
end
