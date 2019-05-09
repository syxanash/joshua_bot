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

      session_buffer = {
          plugin: '',
          is_open: false,
          content: ''
      }
      buffer_file_name = "#{BotConfig.config['temp_directory']}/joshua_#{user_message.chat.id}_buffer.json"

      # initialize the buffer file for the current chat id
      if File.file?(buffer_file_name)
        Logging.log.info "Reading the buffer already created in #{buffer_file_name}..."

        buffer_file_content = File.read(buffer_file_name)
        session_buffer = JSON.parse(buffer_file_content)
      else
        File.write(buffer_file_name, session_buffer.to_json)

        Logging.log.info "Created a new buffer file #{user_message.chat.id}"
      end

      bot_username = bot.api.getMe['result']['username']
      Logging.log.info "Now received: #{user_message.text}, from #{user_message.from.first_name}, in #{user_message.chat.id}"

      AbsPlugin.descendants.each do |lib|
        # for each message create an instance of the plugin library
        plugin = lib.new

        plugin.bot = bot
        plugin.message = user_message
        plugin.buffer_file_name = buffer_file_name
        plugin.stop_command = '/cancel'

        plugin_name = plugin.class.name

        begin
          if session_buffer['is_open'] && session_buffer['plugin'] == plugin_name
            Logging.log.info "Writing message into buffer for plugin #{session_buffer['plugin']}..."

            session_buffer['content'] = user_message.text
            session_buffer['is_open'] = false

            bot.api.send_chat_action(
              chat_id: user_message.chat.id,
              action: 'typing'
            )

            File.write(buffer_file_name, session_buffer.to_json)

            # if we replied to the plugin waiting for answer by the user
            # stop checking further plugins
            break
          elsif session_buffer['is_open']

            # if the current user has a plugin waiting for a reply skip
            # the interpretation of other commands
            next
          elsif !user_message.text.nil?
            # beautify message sent with @ format (used in groups)
            if user_message.text.include? "@#{bot_username}"
              user_message.text.slice! "@#{bot_username}"
            end

            if plugin.command.match(user_message.text)
              # send the match result to do_stuff method if it needs to
              # do something with a particular command requiring arguments
              plugin.do_stuff(Regexp.last_match)

              # if the plugin main regexp does't match the message
              # then show the plugin usage example
            elsif %r{\/#{plugin_name.downcase}?} =~ user_message.text
              plugin.show_usage
            end
          end
        rescue NotImplementedError
          Logging.log.error "Some methods haven't been implemented for plugin #{plugin_name}"
          bot.api.send_message(
            chat_id: user_message.chat.id,
            text: "☢️ #{plugin_name} plugin is not behaving correctly! ☢️"
          )
        rescue CancelOptionException
          Logging.log.info "Manually stopped executing #{plugin_name}"
          bot.api.send_message(
              chat_id: user_message.chat.id,
              text: "⚠️ Stopped executing #{plugin_name} plugin",
              reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
          )
        rescue => e
          Logging.log.error "Cannot execute plugin #{plugin_name}, check if there are tools missing or wild error: #{e.message} #{e.backtrace.inspect}"
          bot.api.send_message(
            chat_id: user_message.chat.id,
            text: "🚫 #{plugin_name} plugin is not working properly on my brain operating system! 🚫"
          )
        end
      end

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
