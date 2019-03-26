# to use this plugin you need to install wget and imagemagick tool convert

require 'json'
require 'securerandom'
require 'rest-client'

class Logos
  REMOTE_LOGOS_LIST_FILE = 'https://logos-c87b5.firebaseio.com/items.json'.freeze

  def initialize(choices = 3)
    raise Exception, 'choices have to be more than 2' if choices < 2

    @answers = []
    file_list = RestClient.get(REMOTE_LOGOS_LIST_FILE)
    list = JSON.parse(file_list)

    raise Exception, 'List of logos to generate is too long' if choices > list.size

    choices.times do
      random_key = list.keys[SecureRandom.random_number(list.keys.size)]
      @answers.push(list[random_key])
      list.tap { |hs| hs.delete(random_key) }
    end
  end

  def correct_answer
    # correct answer is always the first
    # the client must scruble the answers
    # to make things more difficult
    @answers[0]
  end

  def all_answers
    @answers
  end
end

class RandomLogo < Plugin
  def command
    /^\/randomlogo$/
  end

  def do_stuff(_match_results)
    @logos = Logos.new(4)

    @correct_answer_name = @logos.correct_answer['name']
    @correct_answer_url = @logos.correct_answer['url']
    @correct_answer_file = @logos.correct_answer['files'][0]

    answers = [] # array will contain all answers for custom keyboard

    puts '[!] fetching logo with wget'
    system("wget https://s3-us-west-2.amazonaws.com/svgporn.com/logos/#{@correct_answer_file}")
    puts '[!] converting logo from svg to png with imagemagick convert'
    system("convert #{@correct_answer_file} #{@correct_answer_file}.png")

    # scramble all answers because the library logos
    # returns all answers always placing the correct
    # one as the first element of array.

    temp_array = @logos.all_answers
    temp_array.size.times do
      random_pos = Random.rand(temp_array.size)
      answers.push(temp_array[random_pos]['name'])
      temp_array.delete_at(random_pos)
    end

    keyboard_answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: answers.each_slice(1).to_a, one_time_keyboard: true)
    #fr = Telegram::Bot::Types::ForceReply.new(force_reply: true)

    bot.api.sendPhoto(chat_id: message.chat.id, photo: Faraday::UploadIO.new("#{@correct_answer_file}.png", 'image/png'))
    bot.api.sendMessage(chat_id: message.chat.id, text: 'what is this logo?', reply_markup: keyboard_answers)
    File.delete(@correct_answer_file, "#{@correct_answer_file}.png")

    MUST_REPLY
  end

  def do_answer(answer)
    if answer == @correct_answer_name
      bot.api.send_message(chat_id: message.chat.id, text: 'your answer is correct! 👍')
    else
      bot.api.send_message(chat_id: message.chat.id, text: 'your answer is not correct! ❌')
    end

    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.sendMessage(chat_id: message.chat.id, text: "🔎 check out #{@correct_answer_name} at #{@correct_answer_url}", reply_markup: kb)

    STOP_REPLYING
  end
end
