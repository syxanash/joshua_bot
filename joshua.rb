require 'telegram/bot'

require './lib/Plugin'
Dir[File.dirname(__FILE__) + '/lib/plugins/*.rb'].each do |file|
  eval "#{File.read(file)}"
end

token = 'YOUR API TOKEN GOES IN HERE FELLAS!'

# load all plugins into an array knowing the descendants of Plugin
# abstract class
plugins = []
Plugin.descendants.each do |lib|
  plugins << lib.new
  puts "[*] Plugin #{lib} loaded!"
end

Telegram::Bot::Client.run(token) do |bot|
  puts "Bot started..."

  # setting the bot object for all plugins
  plugins.each { |plugin| plugin.bot = bot }

  # searching for new messages
  bot.listen do |message|
    if message.date < Time.now.to_i - 10
      puts "[?] #{message.text} received while you were away from #{message.from.first_name}"
    else
      bot_username = bot.api.getMe()["result"]["username"]
      puts "[?] now received: #{message.text}, from #{message.from.first_name}"

      # set the message for each plugin and check if that message
      # corresponds to a command for a plugin
      plugins.each do |plugin|
        plugin.message = message
        plugin_name = plugin.class.name.downcase

        if plugin.command.match(message.text)
          # send the match result to do_stuff method if it needs to
          # do something with a particular command requiring arguments
          plugin.do_stuff(Regexp.last_match)
        elsif /\/#{plugin_name}(@#{bot_username})?/ =~ message.text
          plugin.show_usage
        end
      end

      # if the message is not a command for any plugin then check with case
      # statement for interpreations. This is used for simple basic commands
      case message.text
      when '/start', "/start@#{bot_username}"
        bot.api.sendMessage(chat_id: message.chat.id, text: "Greetings, Professor Falken.")
      when /josh/i
        bot.api.sendMessage(chat_id: message.chat.id, text: "did somebody just say Joshua?")
      when '/ping', "/ping@#{bot_username}"
        bot.api.sendMessage(chat_id: message.chat.id, text: "pong")
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
