require 'rest-client'
require 'nokogiri'
require 'genius'
require 'similar_text'

class LyricsNotFound < StandardError; end

class LyricsFinder
  # change this constant if you want to increase or decrease the percentage
  # of similarity between the artist entered by the user and the artist
  # found on genius.com
  PERCENTAGE_OF_SIMILARITY = 80

  def initialize(api_key)
    Genius.access_token = api_key
  end

  def lyrics(track_name, track_artist)
    lyrics_text = ''

    # beautify the song name removing the featuring in order to be easily
    # searchable on genius.com

    track_name.gsub!(/\((.*?)\)/, '')
    track_artist.gsub!(/\((.*?)\)/, '')

    track_name.gsub!(/.((ft\.|feat).*?)$/mi, '')
    track_artist.gsub!(/.((ft\.|feat).*?)$/mi, '')

    songs = Genius::Song.search("#{track_artist} #{track_name}")
    song_found = songs.first

    # if first method returns nil or song artist found is not similar by 80%
    # to the artist entered by the user then lyrics is not found

    if song_found.nil? ||
       (song_found.resource['primary_artist']['name'].downcase.similar(track_artist.downcase) < PERCENTAGE_OF_SIMILARITY)
      raise LyricsNotFound, "Lyrics not found for #{track_name}"
    end

    # download html content from the genius.com website and parse the div
    # lyrics downloading only the text removing extra tags

    html_content = RestClient.get(song_found.url)
    doc = Nokogiri::HTML::Document.parse(html_content)

    doc.css('.lyrics').each do |n|
      lyrics_text += n.text.strip
    end

    lyrics_text
  end
end

class Lyrics < AbsPlugin
  def command
    /^\/lyrics$/
  end

  def show_usage
    bot.api.sendMessage(chat_id: message.chat.id, text: 'get lyrics from genius.com with /lyrics')
  end

  def do_stuff(match_results)
    # find our more on how to get a Genius Access Token on: https://genius.com/api-clients
    lyrics_finder = LyricsFinder.new('ENTER YOUR GENIUS Client Access Token HERE!!!')
    track = {:artist => '', :name => ''}

    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    reply_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: %w[yes no],
      one_time_keyboard: true
    )

    bot.api.send_message(chat_id: message.chat.id, text: '🎵 what\'s the name of the song?')
    track[:name] = read_buffer
    bot.api.send_message(chat_id: message.chat.id, text: '🎤 what\'s the name of the artst?')
    track[:artist] = read_buffer
    bot.api.send_message(chat_id: message.chat.id, text: "should I look for the lyrics of the track `#{track[:name]} - #{track[:artist]}`?", parse_mode: 'Markdown', reply_markup: reply_keyboard)
    confirm_reply = read_buffer

    if confirm_reply == 'yes'
      begin
        lyrics = lyrics_finder.lyrics(track[:name], track[:artist])
        bot.api.send_message(chat_id: message.chat.id, text: lyrics, reply_markup: kb)
      rescue LyricsNotFound
        bot.api.send_message(chat_id: message.chat.id, text: 'lyrics not found on genius.com', reply_markup: kb)
      rescue Genius::AuthenticationError
        bot.api.send_message(chat_id: message.chat.id, text: 'error occurred while using genius.com API', reply_markup: kb)
      end

    else
      bot.api.send_message(chat_id: message.chat.id, text: 'ok retype /lyrics', reply_markup: kb)
    end
  end
end
