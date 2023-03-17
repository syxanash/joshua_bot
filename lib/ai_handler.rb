class AiHandler
  def initialize
    @api_token = BotConfig.config['openai']['token']
    @recognize_plugins = BotConfig.config['openai']['recognize_plugins']
    @previous_interactions = []
    @conversation_history = ''

    if !@api_token.empty?
      Logging.log.info 'Initialized OpenAI client'
      @client = OpenAI::Client.new(access_token: @api_token)
    end
  end

  def ask(bot, user_message, message_text)
    return if @api_token.empty?

    matched_plugin = false
    prompt_message = ''
    response_text = ''

    if @recognize_plugins
      plugin_examples = []

      AbsPlugin.descendants.each do |plugin|
        examples_list = plugin.new.examples
        plugin_examples.push(examples_list) unless examples_list.empty?
      end

      if !plugin_examples.empty?
        prompt_message = plugin_prompt(message_text, plugin_examples)

        Logging.log.info 'Sending plugin interpretation to OpenAI...'
        Logging.log.info "Plugin prompt sent:\n#{prompt_message}" if BotConfig.config['openai']['log_prompts']

        bot.api.sendChatAction(chat_id: user_message.chat.id, action: 'typing')

        response_text = send_completions_prompt(prompt_message)
        Logging.log.info "Command received from OpenAI: \"#{response_text}\""

        matched_plugin = PluginHandler.handle(bot, user_message, response_text)
      end
    end

    if !matched_plugin || !@recognize_plugins
      prompt_message = chat_prompt(message_text)

      Logging.log.info 'Sending chat conversation to OpenAI...'
      Logging.log.info "Chat prompt sent:\n#{prompt_message}" if BotConfig.config['openai']['log_prompts']

      bot.api.sendChatAction(chat_id: user_message.chat.id, action: 'typing')

      response_text = send_chat_prompt(prompt_message)
      bot.api.send_message(chat_id: user_message.chat.id, text: response_text)
    end

    @previous_interactions.push({ question: message_text, answer: response_text })
    @previous_interactions.shift if @previous_interactions.size >= BotConfig.config['openai']['max_interaction_history']

    @conversation_history = @previous_interactions.map { |item| "You: #{item[:question]}\nJoshua: #{item[:answer]}" }.join("\n")
  rescue => e
    Logging.log.error "Something went wrong with OpenAI request:\n#{e.message}"
  end

  private

  def send_chat_prompt(prompt_message)
    response = @client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt_message }],
        temperature: 0.5
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def send_completions_prompt(prompt_message)
    response = @client.completions(
      parameters: {
        model: 'text-davinci-003',
        prompt: prompt_message,
        temperature: 0.5,
        max_tokens: 10
      }
    )

    response['choices'].map { |c| c['text'] }.join.lstrip
  end

  def chat_prompt(question)
    generated_prompt = <<~PROMPT
Joshua is a helpful chatbot that lives inside a Raspberry Pi (Zero W to be precise).
He's a very sarcastic bot, he's able to chat with any human who interacts with him.

We start a new conversation with Joshua.
#{@conversation_history}
You: #{question}
Joshua:
    PROMPT

    generated_prompt.chomp
  end

  def plugin_prompt(question, plugin_examples)
    plugin_training_conversation = ''

    plugin_examples.each do |example|
      plugin_training_conversation += example.map { |item| "You: #{item[:description]}\nJoshua: #{item[:command]}\n" }.join
    end

    generated_prompt = <<~PROMPT
Joshua is a helpful chatbot capable of translating text to a programmatic command, for example:

#{plugin_training_conversation}
When no text matches a programmatic command Joshua responds with: UNRECOGNIZED

We start a new conversation with Joshua.
#{@conversation_history}
You: #{question}
Joshua:
    PROMPT

    generated_prompt.chomp
  end
end
