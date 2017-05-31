require 'telegram/bot'

class Plugin
  MUST_REPLY = 1
  STOP_REPLYING = 2

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

  def do_answer(_answer)
    # if plugin needs answer from user, code must be placed here

    raise NotImplementedError, 'You must implement do_answer method'
  end
end
