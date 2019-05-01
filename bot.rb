require 'json'
require 'logger'
require 'securerandom'
require 'fileutils'

bot_temp_directory = '/tmp/joshua_bot_tmp'

# create a folder in tmp directory for this bot
FileUtils.rm_rf bot_temp_directory if File.directory?(bot_temp_directory)
FileUtils.mkdir_p bot_temp_directory

logger = Logger.new("#{bot_temp_directory}/bot_#{SecureRandom.hex(6)}.log")

logger.info 'Reading bot configuration file...'

# load configuration file encoded in json format
config_file = JSON.parse(File.read('config.json'))

token = config_file['token']

if token.empty?
  logger.error 'Missing Telegram Bot API Token from config.json checkout: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
  abort '[?] Remember to write your Telegram bot token in config.json\nMore info: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
end

# get the pool size value. Useful when working with threads
ENV['TELEGRAM_BOT_POOL_SIZE'] = config_file['pool_size']

# finally loading telegram bot wrapper class and plugins
require 'telegram/bot'
require './lib/abs_plugin'

plugins_list = Dir[File.dirname(__FILE__) + "/lib/plugins/*.rb"]

unless config_file['plugin_folder'].empty?
  plugins_list += Dir[File.dirname(__FILE__) + "/lib/plugins/#{config_file['plugin_folder']}/*.rb"]
end

plugins_list_size = plugins_list.length

logger.info "Loading #{config_file['plugin_folder']} plugins..."
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
              bot.api.send_message(chat_id: message.chat.id, text: ">#{"\n" * 40}Shall we play a game?")
            else
              bot.api.send_message(chat_id: message.chat.id, text: 'LOGON:')

              # jump to the next incoming message to safely skip the
              # interpreations of the message just given
              next
            end
          end
        end

        session_buffer = {
          plugin: '',
          is_open: false,
          content: ''
        }
        buffer_file_name = "#{bot_temp_directory}/joshua_#{message.chat.id}_buffer.json"

        # initialize the buffer file for the current chat id
        if File.file?(buffer_file_name)
          logger.info "Reading the buffer already created in #{buffer_file_name}..."

          buffer_file_content = File.read(buffer_file_name)
          session_buffer = JSON.parse(buffer_file_content)
        else
          File.write(buffer_file_name, session_buffer.to_json)

          logger.info "Created a new buffer file #{message.chat.id}"
        end

        bot_username = bot.api.getMe['result']['username']
        logger.info "Now received: #{message.text}, from #{message.from.first_name}, in #{message.chat.id}"

        AbsPlugin.descendants.each do |lib|
          # for each message create an instance of the plugin library
          plugin = lib.new

          plugin.bot = bot
          plugin.message = message
          plugin.buffer_file_name = buffer_file_name
          plugin.stop_command = '/cancel'

          plugin_name = plugin.class.name

          begin
            if session_buffer['is_open'] && session_buffer['plugin'] == plugin_name
              logger.info "Writing message into buffer for plugin #{session_buffer['plugin']}..."

              session_buffer['content'] = message.text
              session_buffer['is_open'] = false

              File.write(buffer_file_name, session_buffer.to_json)
            elsif session_buffer['is_open']
              # if the current user has a plugin waiting for a reply skip
              # the interpretation of other commands
              next
            elsif !message.text.nil?
              # beautify message sent with @ format (used in groups)
              if message.text.include? "@#{bot_username}"
                message.text.slice! "@#{bot_username}"
              end

              if plugin.command.match(message.text)
                # send the match result to do_stuff method if it needs to
                # do something with a particular command requiring arguments
                plugin.do_stuff(Regexp.last_match)

              # if the plugin main regexp does't match the message
              # then show the plugin usage example
              elsif %r{\/#{plugin_name.downcase}?} =~ message.text
                plugin.show_usage
              end
            end
          rescue NotImplementedError
            logger.error "Some methods haven't been implemented for plugin #{plugin_name}"
            bot.api.send_message(chat_id: message.chat.id, text: "☢️ #{plugin_name} plugin is not behaving correctly! ☢️")
          rescue CancelOptionException
            logger.info "Manually stopped executing #{plugin_name}"
            bot.api.send_message(
              chat_id: message.chat.id,
              text: "⚠️ Stopped executing #{plugin_name} plugin",
              reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
            )
          rescue => e
            logger.error "Cannot execute plugin #{plugin_name}, check if there are tools missing or wild error: #{e.message}"
            bot.api.send_message(chat_id: message.chat.id, text: "🚫 #{plugin_name} plugin is not working properly on my brain operating system! 🚫")
          end
        end

        # if the message is not a command for any plugin then check with case
        # statement for interpreations. This is used for simple basic commands
        case message.text
        when '/start', "/start@#{bot_username}"
          bot.api.send_message(chat_id: message.chat.id, text: 'Greetings, Professor Falken.')
        when /josh/i
          bot.api.send_message(chat_id: message.chat.id, text: 'did somebody just say Joshua?')
        when '/users', "/users@#{bot_username}"
          if password_enabled
            bot.api.send_message(chat_id: message.chat.id, text: "Current active chats: #{chat_id_authenticated.size}")
          end
        when '/ping', "/ping@#{bot_username}"
          bot.api.send_message(chat_id: message.chat.id, text: 'pong')
        when '/about', "/about@#{bot_username}"
          text_value = <<-FOO
I was created by my lovely maker ^syx.*$

⚠️ Three Laws of Robotics ⚠️
⚫️ A robot may not injure a human being or, through inaction, allow a human being to come to harm.
⚫️ A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.
⚫️ A robot must protect its own existence as long as such protection does not conflict with the First or Second Law.
FOO
          bot.api.send_message(chat_id: message.chat.id, text: text_value)
        end
      end
    end
  end
end
