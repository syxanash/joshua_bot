require 'rest-client'
require 'cgi'

class Isup < AbsPlugin
  def command
    /\/isup\s?(.+?)$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, parse_mode: "Markdown", text: "check if a website is up with */isup URL*")
  end

  def do_stuff(match_results)
    website = match_results[1]

    url_request = "http://www.isup.me/" + website
    result_msg = website

    resp = RestClient.get(url_request)

    if resp =~ /It\'s just you/i
        result_msg += " is up!"
    else
        result_msg += " looks down from here!"
    end

    bot.api.sendMessage(chat_id: message.chat.id, text: result_msg)
  end
end
