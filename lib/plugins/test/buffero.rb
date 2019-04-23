require 'JSON'

class Buffero < AbsPlugin
  def command
    /\/buffero$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: '/buffero')
  end

  def do_stuff(match_results)
    bot.api.sendMessage(chat_id: message.chat.id, text: 'Enter first number: ')
    first = read_buffer
    bot.api.sendMessage(chat_id: message.chat.id, text: 'Enter second number: ')
    second = read_buffer

    bot.api.sendMessage(chat_id: message.chat.id, text: "Result is #{first.to_i + second.to_i}")
  end

  def read_buffer()
    buffer_file_name = "/tmp/joshua_#{message.chat.id}_buffer.json"

    # open the buffer in order to wait for input from users

    session_buffer = {
      plugin: self.class,
      is_open: true,
      content: ''
    }

    File.write(buffer_file_name, session_buffer.to_json)

    # read the buffer until it's closed

    loop do
      buffer_file_content = File.read(buffer_file_name)

      if buffer_file_content.empty?
        next
      end

      session_buffer = JSON.parse(buffer_file_content)

      unless session_buffer['is_open']
        puts 'buffer is now closed returning the content:'
        puts session_buffer['content']
        break
      end
    end

    File.write(buffer_file_name, {
      plugin: '',
      is_open: false,
      content: ''
    }.to_json)

    session_buffer['content']
  end
end
