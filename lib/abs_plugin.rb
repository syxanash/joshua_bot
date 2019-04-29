require 'telegram/bot'

class CancelOptionException < StandardError; end

class AbsPlugin
  attr_accessor :bot, :message, :buffer_file_name, :stop_command

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

  def read_buffer()
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

      # if the content of the buffer file is empty or is not valid JSON format
      # it means that a process is still writing on it
      # this code should be improved with a thread safe access to the file content

      next if buffer_file_content.empty?

      begin
        session_buffer = JSON.parse(buffer_file_content)
      rescue JSON::ParserError
        next
      end

      break unless session_buffer['is_open']
    end

    # clear the buffer for future plugins
    File.write(buffer_file_name, {
      plugin: '',
      is_open: false,
      content: ''
    }.to_json)

    raise CancelOptionException if session_buffer['content'] == stop_command

    session_buffer['content']
  end
end
