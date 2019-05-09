require 'securerandom'
require 'logger'

module Logging
  def self.log
    @log ||= Logger.new("#{BotConfig.config['temp_directory']}/bot_#{SecureRandom.hex(6)}.log")
  end
end