class Wifinfo < AbsPlugin
  def command
    /^\/wifinfo$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "type:\n/wifinfo to get wifi name and ip address")
  end

  def do_stuff(_match_results)
    wifi_info = `/sbin/iwgetid && /sbin/ifconfig wlan0 | grep "inet addr" | awk '{print $2}'`
    bot.api.send_message(chat_id: message.chat.id, text: wifi_info)
  end
end
