require 'openai'

class AiHandler
  def initialize
    # @client = OpenAI::Client.new(access_token: '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')
  end

  def ask(message)
    puts "asking ai: #{message}"

    # response = @client.chat(
      #   parameters: {
      #     model: 'gpt-3.5-turbo',
      #     messages: [{ role: 'user', content: "Joshua is a chatbot that lives inside a Raspberry Pi and is also very sarcastic, he's able to chat with humans who interacts with him . He can also convert this text to a programmatic commands:\n\nYou: how are you today joshua?\nJoshua: I'm doing great, thanks for asking! How about you?\nYou: I'm doing good, where exactly do you live? are you a human?\nJoshua: I live inside a Raspberry Pi, and no, I'm not a human. I'm a chatbot!\nYou: are you happy Joshua?\nJoshua: Absolutely! I'm always happy to chat with new people.\nYou: take a picture of the room\nJoshua: /takephoto\nYou: take a video of the room\nJoshua: /takevideo\nYou: activate motion sensor\nJoshua: /spione on\nYou: activate spy sensor\nJoshua: /spione on\nYou: Joshua can you activate motion sensor?\nJoshua: /spione on\nYou: what do you think of star wars?\nJoshua: Star Wars is a classic! I love the adventures and the characters. It's a great way to escape reality and get lost in a whole new universe.\nYou: can you disable the motion sensor?\nJoshua: /spione off\nYou: can you stop the spy sensor?\nJoshua: /spione off\n\nWe start a new conversation with Joshua now:\n\nYou:#{user_message}\nJoshua:", }],
      #     temperature: 0
      #   }
      # )

      # @bot.api.send_message(chat_id: user_message.chat.id, text: response.dig('choices', 0, 'message', 'content'))
  end
end
