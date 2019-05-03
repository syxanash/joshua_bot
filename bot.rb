require 'json'
require 'logger'
require 'securerandom'
require 'fileutils'

# load configuration file encoded in json format
config_file = JSON.parse(File.read('config.json'))

# create a folder in tmp directory for this bot
FileUtils.rm_rf config_file['temp_directory'] if File.directory?(config_file['temp_directory'])
FileUtils.mkdir_p config_file['temp_directory']

logger = Logger.new("#{config_file['temp_directory']}/bot_#{SecureRandom.hex(6)}.log")

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
require './lib/bot_message_handler'

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

message_handler = BotMessageHandler.new(config_file, logger)

Telegram::Bot::Client.run(token) do |bot|
  logger.info 'Bot started'

  # searching for new messages
  bot.listen do |user_message|
    # open a thread for every new message to answer users
    # independently from each command.
    Thread.new do
      message_handler.handle(bot, user_message)
    end
  end
end
