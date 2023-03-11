require 'securerandom'
require 'logger'

module Logging
  def self.log
    @log ||= BotConfig.config['prod'] ? Logger.new("#{BotConfig.config['temp_directory']}/bot_#{SecureRandom.hex(6)}.log") : Logger.new($stdout)
  end
end
