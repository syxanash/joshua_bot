require 'rest-client'
require 'open-uri'
require 'json'

class Weather < Plugin
  def command
    /^\/weather\s(.*?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "if you want me to tell you weather forecasts type: /weather *city name*")
  end

  def do_stuff(match_results)
    city = URI::encode(match_results[1])

    begin
      json_response = RestClient.get("http://api.openweathermap.org/data/2.5/weather?q=#{city}")
      decoded_body = JSON.parse(json_response)

      if decoded_body["cod"] == "404"
        bot.api.sendMessage(chat_id: message.chat.id, text: "can't find your place on planet earth! 🌍")
      else
        weather = decoded_body["weather"][0]["description"].downcase
        place = "#{decoded_body["name"]} #{decoded_body["sys"]["country"]}"
        humidity = "#{decoded_body["main"]["humidity"]}% humidity"

        bot.api.sendMessage(chat_id: message.chat.id, text: "my robotic sensors tell me that #{weather} with #{humidity} in #{place} ⛅️")
      end
    rescue
      bot.api.sendMessage(chat_id: message.chat.id, text: "my robotic sensors are not properly working sorry 😵")
    end
  end
end
