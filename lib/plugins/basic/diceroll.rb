class DiceRoll < AbsPlugin
  def command
    /^\/diceroll\s?([1-9]*?)?$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "you can roll a dice with:\n/diceroll *dice faces (default 6)*")
  end

  def do_stuff(match_results)
    dice_max_value = match_results[1]

    max_value = dice_max_value.empty? ? 6 : dice_max_value.to_i
    dice_value = Random.rand(1..max_value)

    bot.api.send_message(chat_id: message.chat.id, text: dice_value)
  end
end
