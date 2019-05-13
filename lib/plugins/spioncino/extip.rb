require 'rest-client'

class Extip < AbsPlugin
  def command
    /^\/extip$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "type:\n/extip to get your external ip")
  end

  def do_stuff(match_results)
    link = "https://httpbin.org/ip"

    json_resp = RestClient.get(link)
    decoded = JSON.parse(json_resp)

    bot.api.sendMessage(chat_id: message.chat.id, text: "my external ip is: #{decoded["origin"]}")
  end
end
