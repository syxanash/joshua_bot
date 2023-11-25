class PluginHandler
  def self.handle(bot, user_message, message_text, show_help = true)
    bot_username = bot.api.getMe['result']['username']
    plugin_triggered = false

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

    Logging.log.info "Trying to match \"#{message_text}\" with a plugin for #{user_message.from.first_name}, in #{user_message.chat.id}"

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
          plugin_triggered = true

          Logging.log.info "Writing message into buffer for plugin #{session_buffer['plugin']}..."

          session_buffer['content'] = message_text
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
          plugin_triggered = true

          # if the current user has a plugin waiting for a reply skip
          # the interpretation of other commands
          next
        elsif !message_text.nil?
          # remove the bot mention "@your_bot_name" from message text (used in groups)
          unmentioned_text = message_text.include?("@#{bot_username}") ? message_text.gsub("@#{bot_username}", '') : message_text

          if plugin.command.match(unmentioned_text)
            plugin_triggered = true

            # send the match result to do_stuff method if it needs to
            # do something with a particular command requiring arguments
            plugin.do_stuff(Regexp.last_match)

            # if the plugin main regexp doesn't match the message
            # then show the plugin usage example
          elsif show_help && %r{\/#{plugin_name.downcase}?} =~ unmentioned_text
            plugin_triggered = true

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
        Logging.log.warn "Manually stopped executing #{plugin_name}"
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

    plugin_triggered
  end
end
