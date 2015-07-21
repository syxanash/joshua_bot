require 'rest-client'
require 'json'

class Butts < Plugin
  def command
    /^\/butts$/
  end

  def do_stuff(match_results)
    number = Random.rand(0..2500)

    begin
      json_resp = RestClient.get("http://api.obutts.ru/butts/#{number}/1/rank/")
      decoded = JSON.parse(json_resp)

      system("wget http://media.obutts.ru/#{decoded[0]["preview"]} -O butt.jpg")

      bot.api.sendPhoto(chat_id: message.chat.id, photo: File.new("butt.jpg"))

      File.delete("butt.jpg")
    rescue
      bot.api.sendMessage(chat_id: message.chat.id, text: "sorry my butts database is not working right now 💋")
    end
  end
end
