require 'rest-client'
require 'json'

class Boops < Plugin
  def command
    /^\/boops$/
  end

  def do_stuff(match_results)
    number = Random.rand(0..3000)
    begin
      json_resp = RestClient.get("http://api.oboobs.ru/boobs/#{number}/1/rank/")
      decoded = JSON.parse(json_resp)

      system("wget http://media.oboobs.ru/#{decoded[0]["preview"]} -O boops.jpg")

      bot.api.sendPhoto(chat_id: message.chat.id, photo: File.new("boops.jpg"))

      File.delete("boops.jpg")
    rescue
      bot.api.sendMessage(chat_id: message.chat.id, text: "sorry my butts database is not working right now 💋")
    end
  end
end
