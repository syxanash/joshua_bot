require 'json'

module BotConfig
  def self.config
    @config ||= JSON.parse(File.read('config.json'))
  end
end