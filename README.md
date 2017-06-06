# Joshua

A *plugins* based bot for [Telegram](https://telegram.org/) messaging app written in *Ruby*.

### cool, now how do I use this bot?

Just write your bot API token in *config.json*. By default *pool size* value is set to 4 because this bot works with threads, but the value can be changed in config.json. You can also set a password if your bot is supposed to be private so that before interpreting commands it asks to enter a password. Oh and you've got to take a look at [this](https://core.telegram.org/bots#3-how-do-i-create-a-bot) if you haven't done it before!

This bot requires the gem [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby).

### super cool, how do I add new plugins?

Take a look at some plugins in `lib/plugins` folder like `diceroll.rb`, `fortune.rb` and `morra.rb` these are very simple plugins that can be easily used as examples for writing your first plugin.

Keep in mind that:
* A plugin must have a **command** method which returns a regexp or a string which will be used to interpret the command that invokes the plugin
* a **do_stuff** method which contains the body of your plugin
* optionally, but required for plugins like *say.rb* or *google.rb*, a **show_usage** method that will appear in case a user invokes a command that needs parameters.
* if a plugin requires further inputs (after giving the first command) write the code inside the method **do_answer** (check out plugin `morra.rb` for a practical example)

### Spioncino bot :boom:

[![demo](http://img.youtube.com/vi/irJc_imOiuo/0.jpg)](http://www.youtube.com/watch?v=irJc_imOiuo)

Check out an awesome usage of this bot as a simple surveillance system for your house on branch [spioncino](https://github.com/syxanash/joshua_bot/tree/spioncino)

### License

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

see `LICENSE.md`
