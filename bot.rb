require 'json'

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
Dir[File.dirname(__FILE__) + '/lib/plugins/*.rb'].each do |file|
  eval "#{File.read(file)}"
end

# check if bot needs password to execute commands
bot_password = config_file['password']
password_enabled = !bot_password.empty?
chat_id_authenticated = {}

# array created to keep track of the threads for each message
threads = []

# load all plugins into an array knowing the descendants of Plugin
# abstract class
plugins = []
Plugin.descendants.each do |lib|
  plugins << lib.new
  puts "[*] Plugin #{lib} loaded..."
end

Telegram::Bot::Client.run(token) do |bot|
  puts 'Bot started...'

  # set the bot object for all plugins
  plugins.each { |plugin| plugin.bot = bot }

  # searching for new messages
  bot.listen do |message|
    if message.date < Time.now.to_i - 10
      puts "[?] #{message.text} received while you were away from #{message.from.first_name}, in #{message.chat.id}"
    else
      # if a password is defined in configuration file, check if user
      # enters the password before giving further commands
      if password_enabled
        # register the message chat id in order to have a unique value
        # for each authorized chat with the bot
        unless chat_id_authenticated.key?(message.chat.id)
          chat_id_authenticated.merge({ message.chat.id => false })
        end

        puts '[?] chat id authorized: '
        p chat_id_authenticated

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

      # open a thread for every new message in order to answer to users
      # independently from each command.
      threads << Thread.new do
        bot_username = bot.api.getMe['result']['username']
        puts "[?] now received: #{message.text}, from #{message.from.first_name}, in #{message.chat.id}"
        plugins.each do |plugin|
          # set the message for each plugin and check if that message
          # corresponds to a command for a plugin
          plugin.message = message
          plugin_name = plugin.class.name.downcase

          begin
            if plugin.command.match(message.text)
              # send the match result to do_stuff method if it needs to
              # do something with a particular command requiring arguments
              plugin.do_stuff(Regexp.last_match)
            elsif /\/#{plugin_name}(@#{bot_username})?/ =~ message.text
              plugin.show_usage
            end
          rescue => e
            puts "[!] Cannot execute plugin #{plugin_name}, check if there are tools missing or wild error: #{e.message}"
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
          bot.api.sendMessage(chat_id: message.chat.id, text: 'pong')
        when '/about', "/about@#{bot_username}"
          text_value = <<-FOO
I was created by my lovely maker syx

⚠️ Three Laws of Robotics ⚠️
⚫️ A robot may not injure a human being or, through inaction, allow a human being to come to harm.
⚫️ A robot must obey any orders given to it by human beings, except where such orders would conflict with the First Law.
⚫️ A robot must protect its own existence as long as such protection does not conflict with the First or Second Law.
FOO
          # See more: https://core.telegram.org/bots/api#replykeyboardhide
          kb = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: text_value, reply_markup: kb)
        when '/stop', "/stop@#{bot_username}"
          # See more: https://core.telegram.org/bots/api#replykeyboardhide
          kb = Telegram::Bot::Types::ReplyKeyboardHide.new(hide_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: 'A strange game. The only winning move is not to play. How about a nice game of chess?', reply_markup: kb)
        end
      end
    end
  end
end
