require 'rest-client'
require 'json'

class Xkcd < AbsPlugin
  def command
    /^\/xkcd\s?([0-9]*?)?$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: "get xkcd comics with\n/xkcd to get the last comic\n/xkcd *comic number*")
  end

  def do_stuff(match_results)
    number = match_results[1]

    begin
      if number.empty?
        # get the last comic published number
        response = RestClient.get('https://xkcd.com/info.0.json')
        decoded = JSON.parse(response)
        # generate random comic from 1 to the last comic published
        random_comic = Random.rand(1..decoded["num"])
        response = RestClient.get("https://xkcd.com/#{random_comic}/info.0.json")
      else
        # or get the one with specified number
        response = RestClient.get("https://xkcd.com/#{number}/info.0.json")
      end

      decoded = JSON.parse(response)
      system("wget \"#{decoded["img"]}\" -O xkcd.png")

      bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('xkcd.png', 'image/png'))

      File.delete('xkcd.png')
    rescue
      bot.api.sendMessage(chat_id: message.chat.id, text: "xkcd comic number you entered does not exist!")
    end
  end
end
