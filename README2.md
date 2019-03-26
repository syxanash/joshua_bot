# Spioncino

An extremely simple surveillance system with **Arduino** and a **Telegram bot**.

*(Update 3/4/2017)* it now works with **Raspberry Pi** too 🍓

### Setting up Arduino and Firmata

Just write your bot API token in *config.json*. By default *pool size* value is set to 4 because this bot works with threads, but the value can be changed in config.json. You can also set a password if your bot is supposed to be private (and I think it should) so that before interpreting commands it asks to enter a password. Oh and you've got to take a look at [this](https://core.telegram.org/bots#3-how-do-i-create-a-bot) if you haven't done it before!

This bot requires the gem [telegram-bot-ruby](https://github.com/atipugin/telegram-bot-ruby).

You also need an **Arduino** platform, a **[PIR](https://www.adafruit.com/products/189)** sensor and a **LED** especially if you like blinking stuff. Remember to upload a standard *[Firmata](https://shokai.github.io/arduino_firmata/)* sketch to your Arduino device. Connect the PIR sensor to the port *7* and the LED to the port *12* of the Arduino board. Connect the board to your bot server via usb and you're ready to go!

Here's a small diagram made with Fritzing:

<img src="http://i.imgur.com/cdqtQeq.png" width="400" height="400" />

### How about Raspberry Pi?

If you have a Raspberry Pi download this repo and instead of using Arduino+Firmata, you can just connect your PIR sensor to the **GPIO** ports following the scheme below, then run the command `/pimotionsensor` rather than `/motionsensor`.

![gpio port](https://i.imgur.com/WFumRlB.png)

### Commands

There are a couple of available commands for *spioncino* bot, here is a list:

Command  | Description
---------|------------
/motionsensor (on/idle/off/status) | Activate *motionsensor* plugin. You can type **on** to turn it on, **idle** to temporarily disable the plugin (but sensor will be still activated) or **off** to terminate the plugin thread. You can get the current status with **status**
/pimotionsensor (on/idle/off/status) | works exclusively for Raspberry Pi and behaves exactly as above
/snapper | take two photos from two different webcams connected to the server (you need to edit the source code if you don't have two webcams available)
/extip | get your external IP address *and rule the world!*

You can add your own plugins to ```lib/plugins``` folder.
Here's the original repo where I released the source code for [my personal](https://github.com/syxanash/joshua_bot) telegram bot.

### About

Quality of the code is really poor, thus I highly suggest not to use this project in real situations :bomb:

This project was actually an experiment I made to learn a few things with *Ruby threads* and *Firmata protocol*.
Unfortunately I have a little spare time and can't seriously work on it but if you have suggestions and advices I'm all ears.

This was a test conducted in order to see if the device was correctly working...

![sith thief](https://i.imgur.com/fkD2C5F.jpg?1)

Here is a demonstration video instead:

[![demo](http://img.youtube.com/vi/irJc_imOiuo/0.jpg)](http://www.youtube.com/watch?v=irJc_imOiuo)
