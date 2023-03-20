require 'telegram/bot'
require 'openai'
require 'json'
require 'fileutils'

require './lib/logging'
require './lib/bot_config'
require './lib/plugin_handler'
require './lib/message_handler'
require './lib/ai_handler'
require './lib/abs_plugin'

# create a folder in tmp directory for this bot
FileUtils.rm_rf BotConfig.config['temp_directory'] if File.directory?(BotConfig.config['temp_directory'])
FileUtils.mkdir_p BotConfig.config['temp_directory']

token = BotConfig.config['token']

if token.empty?
  Logging.log.error 'Missing Telegram Bot API Token from config.json checkout: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
  abort 'Remember to write your Telegram bot token in config.json\nMore info: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
end

if !File.exist? BotConfig.config['openai']['personality_file']
  Logging.log.error 'Missing bot personality file, please take al look at README.md!'
  abort 'Missing bot personality file, please take al look at README.md!'
end

plugins_list = Dir[File.dirname(__FILE__) + "/lib/plugins/*.rb"]

unless BotConfig.config['plugin_folder'].empty?
  plugins_list += Dir[File.dirname(__FILE__) + "/lib/plugins/#{BotConfig.config['plugin_folder']}/*.rb"]
end

plugins_list_size = plugins_list.length

Logging.log.info "Loading #{BotConfig.config['plugin_folder']} plugins..."
Logging.log.info "Found #{plugins_list_size} plugins to load"

plugins_list.each_with_index do |file, i|
  file_name = File.basename file, '.rb'

  Logging.log.info "[#{i + 1}/#{plugins_list_size}] Loading #{file_name.capitalize}..."
  eval File.read(file).to_s
end

message_handler = MessageHandler.new

begin
  Telegram::Bot::Client.run(token) do |bot|
    Logging.log.info 'Bot started'

    # searching for new messages
    bot.listen do |user_message|
      case user_message
      when Telegram::Bot::Types::Message
        # open a thread for every new message to answer users
        # independently from each command.
        Thread.new do
          message_handler.handle(bot, user_message)
        end
      else
        Logging.log.info 'Type not yet implemented'
      end
    end
  end
rescue Telegram::Bot::Exceptions::ResponseError => e
  if e.error_code.to_s == '502'
    Logging.log.error 'Telegram returned error 502'
    retry
  end
rescue Exception => e
  Logging.log.error 'Bot task failed failed unexpectedly, restarting the bot...'
  retry
end
