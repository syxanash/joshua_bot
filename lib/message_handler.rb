class MessageHandler
  def initialize
    # check if bot needs password to execute commands
    @bot_password = BotConfig.config['password']
    @password_enabled = !@bot_password.empty?
    @chat_id_authenticated = {}
    @users_authenticated = []
  end

  def handle(bot, user_message)
    @bot = bot
    message_text = user_message.text

    if user_message.date < Time.now.to_i - 10
      Logging.log.info "#{message_text} received while you were away from #{user_message.from.first_name}, in #{user_message.chat.id}"

      return
    end

    # if a password is defined in configuration file, check if user
    # enters the password before giving further commands
    if @password_enabled
      Logging.log.info "Chat id authorized: #{@chat_id_authenticated}"

      unless @chat_id_authenticated[user_message.chat.id]
        if message_text == @bot_password
          @chat_id_authenticated[user_message.chat.id] = true
          @users_authenticated.push(user_message.from.first_name)

          @bot.api.send_message(
            chat_id: user_message.chat.id,
            text: ">#{"\n" * 40}Shall we play a game?"
          )

          # execute startup commands only after user has successfully logged in
          # the original message object will be cloned and for each command
          # will be sent a message to the bot
          if !BotConfig.config['startup_commands'].empty?
            BotConfig.config['startup_commands'].each do |command|
              Logging.log.info "Executing startup command: `#{command}`"

              matched_plugin = PluginHandler.handle(@bot, user_message, command)
              check_simple_commands(user_message, command) unless matched_plugin
            end
          end
        else
          @bot.api.send_message(chat_id: user_message.chat.id, text: 'LOGON:')

          # jump to the next incoming message to safely skip the
          # interpreations of the message just given
          return
        end
      end
    end

    matched_plugin = PluginHandler.handle(@bot, user_message, message_text)
    check_simple_commands(user_message, message_text) unless matched_plugin
  end

  private

  def check_simple_commands(user_message, message_text)
    bot_username = @bot.api.getMe['result']['username']

    case message_text
    when '/start', "/start@#{bot_username}"
      @bot.api.send_message(
        chat_id: user_message.chat.id,
        text: 'Greetings, Professor Falken.'
      )
    when /josh/i
      @bot.api.send_message(
        chat_id: user_message.chat.id,
        text: 'did somebody just say Joshua?'
      )
    when '/users', "/users@#{bot_username}"
      # users command is valid only when bot access is protected by password
      return unless @password_enabled

      text_value = <<-USERS_AUTH.gsub(/^ {6}/, '')
      Current active users: #{@users_authenticated.size}
      Users authenticated:
      #{@users_authenticated.map { |k| "👤 #{k}\n" }.join('')}
      USERS_AUTH

      @bot.api.send_message(chat_id: user_message.chat.id, text: text_value)
    when '/ping', "/ping@#{bot_username}"
      @bot.api.send_message(chat_id: user_message.chat.id, text: 'pong')
    when '/about', "/about@#{bot_username}"
      text_value = <<-ABOUT.gsub(/^ {6}/, '')
      I was created by my lovely maker ^syx.*$

      ⚠️ Three Laws of Robotics
      🤖️ A robot may not injure a human being or, through inaction, allow a human being to come to harm.
      🤖️ A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.
      🤖️ A robot must protect its own existence as long as such protection does not conflict with the First or Second Law.
      ABOUT
      @bot.api.send_message(chat_id: user_message.chat.id, text: text_value)
    when '/stop', "/stop@#{bot_username}"
      @bot.api.send_message(
        chat_id: user_message.chat.id,
        text: ">#{"\n" * 40}A strange game. The only winning move is not to play",
        reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      )
    end
  end
end
