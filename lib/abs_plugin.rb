require 'telegram/bot'

class AbsPlugin
  attr_accessor :bot, :message

  # the following two methods will be used to know the plugins name which
  # inherited from the class Plugin
  def self.descendants
    @descendants ||= []
  end

  def self.inherited(descendant)
    descendants << descendant
  end

  def show_usage
    # show usage by default calls do_stuff, if you want to show a help message
    # to a user you can override this method in your plugin class
    do_stuff(0)
  end

  def command
    # this method when overridden must contain the string or regexp
    # to invoke the plugin command

    raise NotImplementedError, 'You must implement command method'
  end

  def do_stuff(_match_results)
    # must contain the body of your plugins using telegram api

    raise NotImplementedError, 'You must implement do_stuff method'
  end

  # returns the temporary file where the plugin buffer will be saved
  def self.get_buffer_filename(chat_id)
    "/tmp/joshua_#{chat_id}_buffer.json"
  end

  def read_buffer()
    buffer_file_name = self.class.get_buffer_filename(message.chat.id)

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
