require 'rest-client'
require 'open-uri'

class Artist < AbsPlugin
  def command
    /^\/artist (.+?)$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "if you want get info about an artist type:\n/artist *Maher Zain*")
  end

  def do_stuff(match_results)
    artist_name = URI::encode(match_results[1])

    json_resp = RestClient.get("http://api.spotify.com/v1/search?q=#{artist_name}&type=artist")
    decoded = JSON.parse(json_resp)

    if decoded['artists']['items'].empty?
      bot.api.send_message(chat_id: message.chat.id, text: 'Your artist name doesn\'t exist on my database 😞')
    else
      name = "#{decoded['artists']['items'][0]['name']}"
      category = "#{decoded['artists']['items'][0]['type']}"
      followers = "#{decoded['artists']['items'][0]['followers']['total']}"
      popularity = "#{decoded['artists']['items'][0]['popularity']}"

      output_message = <<-MSG
🎶 I found on Spotify:
Name: #{name}
Category: #{category}
Popularity: #{popularity}
Total Follower: #{followers}
MSG

      bot.api.send_message(chat_id: message.chat.id, text: output_message)
    end
  end
end
