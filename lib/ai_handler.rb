class AiHandler
  MAX_INTERACTIONS_MEMORY = 10

  def initialize(token)
    @api_token = token
    @previous_interactions = []

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

      response_text = response.dig('choices', 0, 'message', 'content')
      bot.api.send_message(chat_id: user_message.chat.id, text: response_text)

      @previous_interactions.push({ question: message_text, answer: response_text })
      @previous_interactions.shift if @previous_interactions.size >= MAX_INTERACTIONS_MEMORY
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

#{@previous_interactions.map { |item| "You: #{item[:question]}\nJoshua: #{item[:answer]}" }.join("\n")}
You: #{question}
Joshua:
    PROMPT
  end
end
