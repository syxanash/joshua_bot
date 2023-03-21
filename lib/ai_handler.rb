class AiHandler
  def initialize
    @api_token = BotConfig.config['openai']['token']

    return if @api_token.empty?

    @recognize_plugins = BotConfig.config['openai']['recognize_plugins']
    @personality = File.read(BotConfig.config['openai']['personality_file'])
    @previous_interactions = []
    @conversation_history = ''
    @plugin_training_conversation = ''

    Logging.log.info 'Initialized OpenAI client'
    @client = OpenAI::Client.new(access_token: @api_token)

    if @recognize_plugins
      Logging.log.info 'Loading plugins examples for text to command prompt...'
      AbsPlugin.descendants.each do |plugin|
        plugin_instance = plugin.new
        examples_list = plugin_instance.examples

        examples_match_commands = examples_list.map { |example| plugin_instance.command.match?(example[:command]) }.all?

        if !examples_match_commands
          Logging.log.warn "#{plugin_instance.class.name} plugin examples don't match the command!"
        end

        if !examples_list.empty? && examples_match_commands
          @plugin_training_conversation += examples_list.map { |item| "You: #{item[:description]}\nJoshua: #{item[:command]}\n" }.join
        end
      end
    end
  end

  def ask(bot, user_message, message_text)
    return if @api_token.empty?

    matched_plugin = false
    prompt_message = ''
    response_text = ''

    if @recognize_plugins
      prompt_message = plugin_prompt(message_text)

      Logging.log.info 'Sending plugin prompt to OpenAI...'
      Logging.log.info "Plugin prompt sent:\n#{prompt_message}" if BotConfig.config['openai']['log_prompts']

      bot.api.sendChatAction(chat_id: user_message.chat.id, action: 'typing')

      response_text = send_completions_prompt(prompt_message)
      Logging.log.info "Command received from OpenAI: \"#{response_text}\""

      matched_plugin = PluginHandler.handle(bot, user_message, response_text)
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
    bot.api.send_message(
      chat_id: user_message.chat.id,
      text: 'Sorry, feeling a bit dizzy today, could you repeat that again? 😵‍💫',
      reply_to_message_id: user_message.message_id
    )
  end

  private

  def send_chat_prompt(prompt_message)
    response = @client.chat(
      parameters: {
        model: 'gpt-3.5-turbo',
        messages: [{ role: 'user', content: prompt_message }],
        temperature: 0
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def send_completions_prompt(prompt_message)
    response = @client.completions(
      parameters: {
        model: 'text-davinci-003',
        prompt: prompt_message,
        temperature: 0.7,
        max_tokens: 10
      }
    )

    response['choices'].map { |c| c['text'] }.join.lstrip
  end

  def plugin_prompt(question)
    generated_prompt = <<~PROMPT
Joshua is a chatbot capable of translating text to a programmatic command, for example:

#{@plugin_training_conversation}
When no text matches a programmatic command Joshua responds with: UNRECOGNIZED

We start a new conversation with Joshua.

You: #{question}
Joshua:
    PROMPT

    generated_prompt.chomp
  end

  def chat_prompt(question)
    generated_prompt = <<~PROMPT
Joshua is a helpful chatbot who enjoys chatting with any human who interacts with him.
#{@personality}

We start a new conversation with Joshua.
#{@conversation_history}
You: #{question}
Joshua:
    PROMPT

    generated_prompt.chomp
  end
end
