require 'erb'
include ERB::Util

class Google < AbsPlugin
  def command
    /\/google (.+) for (.+?)$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "if you want to use this command type:\n/google *something* for *someone*")
  end

  def do_stuff(match_results)
    stuff = url_encode(match_results[1])
    user = match_results[2]

    bot.api.send_message(chat_id: message.chat.id, text: "#{user}: http://lmgtfy.com/?q=#{stuff}")
  end
end
