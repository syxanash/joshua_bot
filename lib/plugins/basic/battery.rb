# this plugin works on OSX

class Battery < Plugin
  def command
    '/battery'
  end

  def do_stuff(match_results)
    battery = %x(pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';')
    bot.api.sendMessage(chat_id: message.chat.id, text: "Battery status: #{battery}")
  end
end
