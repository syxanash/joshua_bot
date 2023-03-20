# this plugin works on OSX

class Battery < AbsPlugin
  def command
    /^\/battery$/
  end

  def examples
    [
      { command: '/battery', description: 'get the battery percentage of the device the bot is running on'}
    ]
  end

  def do_stuff(match_results)
    battery = %x(pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';')
    bot.api.send_message(chat_id: message.chat.id, text: "Battery status: #{battery}")
  end
end
