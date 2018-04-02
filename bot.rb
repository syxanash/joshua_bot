require 'json'
require 'logger'
require 'securerandom'

logger = Logger.new("/tmp/joshua_bot_#{SecureRandom.hex(6)}.log")

logger.info 'Reading bot configuration file...'

# load configuration file encoded in json format
config_file = JSON.parse(File.read('config.json'))

token = config_file['token']

if token.empty?
  abort '[?] Remember to write your Telegram bot token in config.json\nMore info: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
end

# worst solution ever I know but will be fixed!
# get the pool size value. Useful when working with threads
ENV['TELEGRAM_BOT_POOL_SIZE'] = config_file['pool_size']

# finally loading telegram bot wrapper class and plugins
require 'telegram/bot'
require './lib/Plugin'

plugins_list = Dir[File.dirname(__FILE__) + '/lib/plugins/*.rb']
plugins_list_size = plugins_list.length

logger.info "Found #{plugins_list_size} plugins to load"

plugins_list.each_with_index do |file, i|
  file_name = File.basename file, '.rb'

  logger.info "[#{i + 1}/#{plugins_list_size}] Loading #{file_name.capitalize}..."
  eval File.read(file).to_s
end

# check if bot needs password to execute commands
bot_password = config_file['password']
password_enabled = !bot_password.empty?
chat_id_authenticated = {}

# hash structure which contains user chat id and instance of the plugin
# which needs a reply from the user
waiting_input = {}

Telegram::Bot::Client.run(token) do |bot|
  logger.info 'Bot started'

  # searching for new messages
  bot.listen do |message|
    # open a thread for every new message to answer users
    # independently from each command.
    Thread.new do
      if message.date < Time.now.to_i - 10
        logger.info "#{message.text} received while you were away from #{message.from.first_name}, in #{message.chat.id}"
      else
        # if a password is defined in configuration file, check if user
        # enters the password before giving further commands
        if password_enabled
          logger.info "Chat id authorized: #{chat_id_authenticated}"

          unless chat_id_authenticated[message.chat.id]
            if message.text == bot_password
              chat_id_authenticated[message.chat.id] = true
              bot.api.sendMessage(chat_id: message.chat.id, text: ">#{"\n" * 50}Shall we play a game?")
            else
              bot.api.sendMessage(chat_id: message.chat.id, text: 'LOGON:')

              # jump to the next incoming message to safely skip the
              # interpreations of the message just given
              next
            end
          end
        end

        bot_username = bot.api.getMe['result']['username']
        logger.info "Now received: #{message.text}, from #{message.from.first_name}, in #{message.chat.id}"

        Plugin.descendants.each do |lib|
          # for each message create an instance of the plugin library
          plugin = lib.new

          # set bot and message object for each plugin
          # and save the name of the plugin

          plugin.bot = bot
          plugin.message = message
          plugin_name = plugin.class.name

          begin
            # check if a plugin is waiting for a user to give a reply
            if waiting_input[message.chat.id].class.name == plugin_name
              # restore old plugin instance to send reply to the user
              old_plugin_instance = waiting_input[message.chat.id]

              response = old_plugin_instance.do_answer(message.text)

              # if plugin doesn't need further replies then stop the plugin
              # from waiting new inputs
              if response == Plugin::STOP_REPLYING
                waiting_input.delete(message.chat.id)
              end

            # if the current user has a plugin waiting for a reply skip
            # the interpretation of other commands
            elsif !waiting_input[message.chat.id].nil?
              next
            elsif !message.text.nil?
              # beautify message sent with @ format (used in groups)
              if message.text.include? "@#{bot_username}"
                message.text.slice! "@#{bot_username}"
              end

              if plugin.command.match(message.text)
                # send the match result to do_stuff method if it needs to
                # do something with a particular command requiring arguments
                response = plugin.do_stuff(Regexp.last_match)

                # if plugin needs a reply then store user chat id and plugin
                # instance inside a hash structure
                if response == Plugin::MUST_REPLY
                  waiting_input[message.chat.id] = plugin
                end

              # if the plugin main regexp does't match the message
              # then show the plugin usage example
              elsif %r{\/#{plugin_name.downcase}?} =~ message.text
                plugin.show_usage
              end
            end
          rescue NotImplementedError
            bot.api.sendMessage(chat_id: message.chat.id, text: "☢️ #{plugin_name} plugin is not behaving correctly! ☢️")

            # in case a do_answer wasn't implemented for the plugin
            # remove the user from the waiting input list
            waiting_input.delete(message.chat.id)
          rescue => e
            logger.error "Cannot execute plugin #{plugin_name}, check if there are tools missing or wild error: #{e.message}"
            bot.api.sendMessage(chat_id: message.chat.id, text: "🚫 #{plugin_name} plugin is not working properly on my brain operating system! 🚫")
          end
        end

        # if the message is not a command for any plugin then check with case
        # statement for interpreations. This is used for simple basic commands
        case message.text
        when '/start', "/start@#{bot_username}"
          bot.api.sendMessage(chat_id: message.chat.id, text: 'Greetings, Professor Falken.')
        when /josh/i
          bot.api.sendMessage(chat_id: message.chat.id, text: 'did somebody just say Joshua?')
        when '/ping', "/ping@#{bot_username}"
          bot.api.send_message(chat_id: message.chat.id, text: 'pong')
        when '/about', "/about@#{bot_username}"
          text_value = <<-FOO
I was created by my lovely maker syx

⚠️ Three Laws of Robotics ⚠️
⚫️ A robot may not injure a human being or, through inaction, allow a human being to come to harm.
⚫️ A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.
⚫️ A robot must protect its own existence as long as such protection does not conflict with the First or Second Law.
FOO
          bot.api.sendMessage(chat_id: message.chat.id, text: text_value)
        when '/stop', "/stop@#{bot_username}"
          # remove user from the waiting input list and remove custom keyboard
          # if it was previously enabled by some plugin

          waiting_input.delete(message.chat.id)
          kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: 'A strange game. The only winning move is not to play. How about a nice game of chess?', reply_markup: kb)
        end
      end
    end
  end
end
