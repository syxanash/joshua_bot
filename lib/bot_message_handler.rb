class BotMessageHandler
  def handle(bot, user_message)
    # check if bot needs password to execute commands
    bot_password = BotConfig.config['password']
    password_enabled = !bot_password.empty?
    chat_id_authenticated = {}

    if user_message.date < Time.now.to_i - 10
      Logging.log.info "#{user_message.text} received while you were away from #{user_message.from.first_name}, in #{user_message.chat.id}"
    else
      # if a password is defined in configuration file, check if user
      # enters the password before giving further commands
      if password_enabled
        Logging.log.info "Chat id authorized: #{chat_id_authenticated}"

        unless chat_id_authenticated[user_message.chat.id]
          if user_message.text == bot_password
            chat_id_authenticated[user_message.chat.id] = true

            bot.api.send_message(
              chat_id: user_message.chat.id,
              text: ">#{"\n" * 40}Shall we play a game?"
            )
          else
            bot.api.send_message(chat_id: user_message.chat.id, text: 'LOGON:')

            # jump to the next incoming message to safely skip the
            # interpreations of the message just given
            return
          end
        end
      end

      # check if the command sent by user is a plugin invocation
      PluginHandler.handle(bot, user_message)

      bot_username = bot.api.getMe['result']['username']

      # if the message is not a command for any plugin then check with case
      # statement for interpreations. This is used for simple basic commands
      case user_message.text
      when '/start', "/start@#{bot_username}"
        bot.api.send_message(chat_id: user_message.chat.id, text: 'Greetings, Professor Falken.')
      when /josh/i
        bot.api.send_message(chat_id: user_message.chat.id, text: 'did somebody just say Joshua?')
      when '/users', "/users@#{bot_username}"
        if password_enabled
          bot.api.send_message(chat_id: user_message.chat.id, text: "Current active chats: #{chat_id_authenticated.size}")
        end
      when '/ping', "/ping@#{bot_username}"
        bot.api.send_message(chat_id: user_message.chat.id, text: 'pong')
      when '/about', "/about@#{bot_username}"
        text_value = <<~ABOUT
          I was created by my lovely maker ^syx.*$

          ⚠️ Three Laws of Robotics
          🤖️ A robot may not injure a human being or, through inaction, allow a human being to come to harm.
          🤖️ A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.
          🤖️ A robot must protect its own existence as long as such protection does not conflict with the First or Second Law.
        ABOUT
        bot.api.send_message(chat_id: user_message.chat.id, text: text_value)
      end
    end
  end
end
