require 'rest-client'
require 'open-uri'
require 'json'

class Film < Plugin
  def command
    /^\/film (.+?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want get info about a movie type:\n/film *movie name*")
  end

  def do_stuff(match_results)
    movie_name = URI::encode(match_results[1])

    json_resp = RestClient.get("http://www.imdbapi.com/?t=#{movie_name}")
    decoded = JSON.parse(json_resp)

    if decoded["Response"] =~ /True/i
      bot.api.sendMessage(chat_id: message.chat.id, text: "I found on IMDB: #{decoded["Title"]}\n📌#{decoded["Plot"]}\n🎥#{decoded["Country"]} #{decoded["Year"]}")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Your movie name doesn't exist on my database 😞")
    end
  end
end
