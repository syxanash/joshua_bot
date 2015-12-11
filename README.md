# Joshua

![WOPR computer](https://i.imgur.com/w4UBkRX.gif)

A *plugins* based bot for [Telegram](https://telegram.org/) messaging app written in *Ruby*.

### cool, now how do I use this bot?

Just write your bot API token in *config.json*. By default *pool size* value is set to 4 because this bot works with threads, but the value can be changed in config.json. You can also set a password if your bot is supposed to be private so that before interpreting commands it asks to enter a password. Oh and you've got to take a look at [this](https://core.telegram.org/bots#3-how-do-i-create-a-bot) if you haven't done it before!

This bot requires the gem [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby).

### super cool, how do I add new plugins?

Take a look at some plugins in `lib/plugins` folder like *diceroll.rb* or *fortune.rb* these are very simple plugins that can be easily hacked.

* A plugin must have a **command** method which returns a regexp or a string to parse the command that will invoke the plugin
* a **do_stuff** method which contains the body of your plugin
* optionally, but required for plugins like *say.rb* or *google.rb*, a **show_usage** method that will appear in case a user invokes a command that needs parameters or perhaps was invoked specifying the bot name like `plugin_command@bot_name` in a group chat.

Remember that argument **match_results** for **do_stuff** method can be used if your plugin needs to parse parameters and that the list of values to be parsed starts from 1. (this one will be fixed)

### Spioncino bot :boom:

[![demo](http://img.youtube.com/vi/irJc_imOiuo/0.jpg)](http://www.youtube.com/watch?v=irJc_imOiuo)

Check out an awesome usage of this bot as a simple surveillance system for your house on branch [spioncino](https://github.com/syxanash/joshua_bot/tree/spioncino)

### TO FIX

A lot of stuff, but have no time... one day... perhaps...

### Author

Me of course!

### License

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

```
Copyright (c) 2015 Simone Marzulli

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
