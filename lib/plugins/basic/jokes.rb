require 'rest-client'
require 'json'
require 'cgi'

class Jokes < Plugin
  def command
    /\/jokes\s?(.*?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want to make joke on someone type:\n/jokes *someone*")
  end

  def do_stuff(match_results)
    user = match_results[1]

    url_request = "http://api.icndb.com/jokes/random"

    unless user.empty?
      user_data = user.split(" ")
      url_request += "?firstName=#{user_data[0]}&lastName=#{user_data[1]}"
    end

    json_resp = RestClient.get(url_request)
    decoded = JSON.parse(json_resp)

    bot.api.sendMessage(chat_id: message.chat.id, text: CGI.unescapeHTML(decoded["value"]["joke"]))
  end
end
