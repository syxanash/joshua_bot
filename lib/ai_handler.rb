require 'openai'

class AiHandler
  def initialize(token)
    @api_token = token
    if !@api_token.empty?
      Logging.log.info 'Initialized OpenAI client'
      @client = OpenAI::Client.new(access_token: @api_token)
    end
  end

  def ask(bot, user_message, message_text)
    return if @api_token.empty?

    Logging.log.info 'Sending user message inside prompt to OpenAI...'

    begin
      response = @client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [{ role: 'user', content: prompt(message_text) }],
          temperature: 0.5
        }
      )
      bot.api.send_message(chat_id: user_message.chat.id, text: response.dig('choices', 0, 'message', 'content'))
    rescue => e
      Logging.log.error "Something went wrong with OpenAI request:\n#{e.message}"
    end
  end

  private

  def prompt(question)
    <<~PROMPT
Joshua is a chatbot that lives inside a Raspberry Pi (Zero W to be precise).
He's a very sarcastic bot, he's able to chat with any human who interacts with him.

We start a new conversation with Joshua.

You: #{question}
Joshua:
    PROMPT
  end
end
