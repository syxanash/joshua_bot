require 'rest-client'
require 'open-uri'
require 'json'

class Movie < AbsPlugin
  def command
    /^\/movie (.+?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want get info about a movie type:\n/movie *Game of Thrones*")
  end

  def do_stuff(match_results)
    movie_name = URI::encode(match_results[1])

    json_resp = RestClient.get("http://www.omdbapi.com/?t=#{movie_name}")
    decoded = JSON.parse(json_resp)

    if decoded["Response"] =~ /True/i
      bot.api.sendMessage(chat_id: message.chat.id, text: " I found on OMDB:\nTitle: #{decoded["Title"]} \nYear: #{decoded["Year"]} \nGenre: #{decoded["Genre"]}")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Your movie name doesn't exist on my database 😞")
    end
  end
end
