require 'rest-client'
require 'open-uri'
require 'json'

class Artist < Plugin
  def command
    /^\/artist (.+?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want get info about a artist type:\n/artist *Maher Zain*")
  end

  def do_stuff(match_results)
    artist_name = URI::encode(match_results[1])
   
    json_resp = RestClient.get("http://api.spotify.com/v1/search?q=#{artist_name}&type=artist")
    decoded = JSON.parse(json_resp)

    if decoded

      name = "#{decoded["artists"]["items"][0]["name"]}"
      category = "#{decoded["artists"]["items"][0]["type"]}"
      followers = "#{decoded["artists"]["items"][0]["followers"]["total"]}"
      popularity = "#{decoded["artists"]["items"][0]["popularity"]}"

      bot.api.sendMessage(chat_id: message.chat.id, text: "I found on Spotify:\n Name : #{name} \n Category : #{category}\n  Popularity : #{popularity}\n Total Follower : #{followers}\n ")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Your artist name doesn't exist on my database 😞")
    end
  end
end



