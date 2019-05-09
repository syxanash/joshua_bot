require 'json'
require 'fileutils'
require './lib/logging'
require './lib/bot_config'

include Logging
include BotConfig

# create a folder in tmp directory for this bot
FileUtils.rm_rf BotConfig.config['temp_directory'] if File.directory?(BotConfig.config['temp_directory'])
FileUtils.mkdir_p BotConfig.config['temp_directory']

token = BotConfig.config['token']

if token.empty?
  Logging.log.error 'Missing Telegram Bot API Token from config.json checkout: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
  abort '[?] Remember to write your Telegram bot token in config.json\nMore info: https://core.telegram.org/bots#3-how-do-i-create-a-bot'
end

# get the pool size value. Useful when working with threads
ENV['TELEGRAM_BOT_POOL_SIZE'] = BotConfig.config['pool_size']

# finally loading telegram bot wrapper class and plugins
require 'telegram/bot'
require './lib/abs_plugin'
require './lib/bot_message_handler'

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

message_handler = BotMessageHandler.new()

Telegram::Bot::Client.run(token) do |bot|
  Logging.log.info 'Bot started'

  # searching for new messages
  bot.listen do |user_message|
    # open a thread for every new message to answer users
    # independently from each command.
    Thread.new do
      message_handler.handle(bot, user_message)
    end
  end
end
