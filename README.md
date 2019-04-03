# Joshua

![logo](other/doc_assets/joshua.png)

A *plugins* based bot for [Telegram](https://telegram.org/) messaging app written in Ruby.

## Installation

Clone this repository and then run `bundle` to install the dependencies.

```
$ git clone git@github.com:syxanash/joshua_bot.git
$ cd joshua_bot
$ bundle install
```

## Usage

Enter a valid bot API token in `config.json` (see **Configure** below) then run the bot with:

```
$ ruby bot.rb
```

A log file will be created in `/tmp` directory with a random name (e.g. `joshua_bot_1b3510f004bd.log`)

## Configure

### Bot API Token

Before running the bot you need to add a telegram API key for your bot to the file `config.json`. Check out the official [telgram documentation](https://core.telegram.org/bots#3-how-do-i-create-a-bot) to achieve this.

Here's an example of a `config.json` once you have your API key set up:

```
{
  "token": "103414657:AAGh0I6l-CKf_TDu6CUNa7c7MgnfRbUDzMQ",
  "pool_size": "4",
  "plugin_folder": "basic",
  "password": ""
}
```

### Plugin Set

If you take a look at the folder `lib/plugins/` you will find different sub folders containing various plugins inside. By default the plugins loaded on the bot are in `basic/`. Alternatively you can specify a different set in the `config.json` modifying the value `plugin_folder` (e.g. `"spioncino"`) .

You can create your own set of plugins and drag plugins from other sets by making a new folder in `lib/plugins/`, for instance:

```
$ mkdir lib/plugins/workinprogress
```
Once you've done that you can specify the folder `"workinprogress"` inside `config.json`.

**Notice** that the plugin `help.rb` will always be loaded since it resides in the root directory of the plugins `lib/plugins`. You can place in this folder all the plugins which will always be loaded by the bot.

### Bot Password

If you want to be the only one talking to your bot you can add a **tiny** layer of security setting up a *bot password*. By doing so everytime you start the conversation with the bot it will ask you for a password before interpreting various commands.

You can set a bot password in the `config.json` under the value `"password"`.

## Create Plugins

Each plugin is a class which extends the class `AbsPlugin`. A plugin should have the following four methods:

* `initialize` (not mandatory)
* `command`
* `show_usage`
* `do_stuff`
* `do_answer` (not mandary)

You can place a new plugin in the folder `lib/plugins` or inside a subfolder of this directory to group plugins in sets. For example `basic/` and `spioncino/` are two sets of plugins.

### initialize

It's a method used to *initialize* class variables and other settings used by the plugin. This method will be called when the bot is loading the plugins for the first time. Also see Ruby [object initialization](https://ruby-doc.org/docs/ruby-doc-bundle/UsersGuide/rg/objinitialization.html).

### command

This method should return the **regular expression** used to match a command which the bot will interpret. For instance:

```
def command
  /^\/fortune$/
end
```

In this case the plugin will be activated upon entering the command `/fortune`. A slightly more complex command could be instad:

```
def command
  /(^\/takephoto$|photo)/
end
```

Which will interpret either `/takephoto` or simply `photo`.

### show_usage

You can display a help message to show the user the correct usage of the plugin. This method will be called when the user invokes the command in a wrong way for example if the command requires additional parameters.

For instance the plugin **NoirSensor** will call the method `show_usage` if the user invokes the command `/noirsensor` without parameters. A correct usage of the plugin NoirSensor would be `/noirsensor on`.

### do_stuff

This method will contain the actual code executed when the command is invoked. You can send simple text messages to the user (see the plugin **Fortune**), images (see **Xkcd** plugin) or audio messages (see **spioncino/Say**).

Additional command's parameters will be stored in the formal parameter `match_result` of the method `do_stuff`. The plugin's additional parameters will be created if you define a regular expression which accepts extra parameters like:

`/^\/diceroll\s?([1-9]*?)?$/`

In this case **DiceRoll** plugin can be invoked by using the command `/diceroll` or you can pass an extra parameter as an integer like so: `/diceroll 50` (this plugin will now generate a random number from 1-50). `match_result` is an array which will contain all the captured variables of the matched plugin's regex.

### do_answer

You can create plugins which will reply to user's inputs by returning the constant `MUST_REPLY` in the method `do_stuff()`. In this case the method `do_answer` will be invoked subsequently and you can place in here the code which will handle the user's answer.

Take a look at the plugin **Morra**, in this case the plugin sends a message and expects a reply, an emoji containig 🗿 📄 ✂️, so we return the constant `MUST_REPLY` at the end of the method. After the user replied with a text message the `do_answer` method will manage the answer.

The formal parameter `human_choice` contains user's answer as a string format.

When `MUST_REPLY` is returned by `do_stuff` any other messages sent by the user will go into `do_answer` (including other valid commands). In order to interrupt the flow you can return the constant `STOP_REPLYING` by the method `do_answer`.

Check out these plugins which use `do_answer`:

* `morra.rb`
* `lyrics.rb`
* `randomlogo.rb`

## Spioncino

![ruby lady](other/doc_assets/ruby-lady.png)

You should definitely tell your wife about an awesome implementation of this bot as a simple surveillance system for your mansion: [spioncino](SPIONCINO.md)

## Contributing

I've mostly devleoped this project in my freetime to learn Ruby and to play with Raspberry Pi & Arduino. I've certainly left some bugs and if you want to point out some code improvements feel free to open a PR!

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE.txt)
