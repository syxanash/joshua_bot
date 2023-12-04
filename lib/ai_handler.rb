class EmptyVoiceMessageException < StandardError; end

class AiHandler
  def initialize
    @api_token = BotConfig.config['openai']['token']

    return if @api_token.empty?

    @recognize_plugins = BotConfig.config['openai']['recognize_plugins']
    @personality = File.read(BotConfig.config['openai']['personality_file'])
    @plugins_list_prompt_segment = ''
    @chat_history = []
    @text_to_command_training = [
      {
        role: 'system',
        content: 'You are a text to command converter, you will only reply with commands given a text by a user and nothing else. I will give you some examples of commands and when a command is not found in these examples, you must reply with UNRECOGNIZED.',
      }
    ]

    first_example_plugin_commands = []

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
          first_example_plugin_commands.push(examples_list[0][:command])

          @text_to_command_training += examples_list.map do |item|
            [
              { role: 'user', content: item[:description] },
              { role: 'assistant', content: item[:command] }
            ]
          end.flatten
        end
      end

      @plugins_list_prompt_segment = "Joshua can also reply just with the following commands: #{first_example_plugin_commands.join(' ')}"
    end
  end

  def ask(bot, user_message, message_text)
    return if @api_token.empty?

    matched_plugin = false
    nested_matched_plugin = false
    response_text = ''

    # if user sends voice message use whisper to transcribe it
    # and then use the text for interpreting plugin commands or chatgpt interaction
    unless user_message.voice.nil?
      file_url = JSON.parse(RestClient.get("https://api.telegram.org/bot#{BotConfig.config['token']}/getFile?file_id=#{user_message.voice.file_id}"))
      audio_file_url = "https://api.telegram.org/file/bot#{BotConfig.config['token']}/#{file_url['result']['file_path']}"

      local_audio_file = "#{BotConfig.config['temp_directory']}/msg_audio_#{user_message.voice.file_id}"

      Logging.log.info 'Downloading voice message and converting to mp3...'
      system("wget #{audio_file_url} -O #{local_audio_file}.ogg")
      system("ffmpeg -i #{local_audio_file}.ogg -acodec libmp3lame -aq 4 #{local_audio_file}.mp3")

      Logging.log.info 'Sending audio file to OpenAI for transcription...'
      transcription = transcribe("#{local_audio_file}.mp3")
      Logging.log.info "Message transcribed received: \"#{transcription}\""

      File.delete("#{local_audio_file}.ogg", "#{local_audio_file}.mp3")

      raise EmptyVoiceMessageException if transcription.empty?

      message_text = transcription
    end

    @chat_history.push(
      {
        role: 'user',
        content: message_text
      }
    )

    if @recognize_plugins
      user_command_request = @text_to_command_training.clone
      user_command_request.push(
        {
          role: 'user',
          content: message_text
        }
      )

      Logging.log.info 'Sending plugin prompt to OpenAI...'
      Logging.log.info "Plugin training sent:\n#{user_command_request}" if BotConfig.config['openai']['log_prompts']

      bot.api.sendChatAction(chat_id: user_message.chat.id, action: 'typing')

      response_text = send_interpret_command(user_command_request)
      Logging.log.info "Command received from OpenAI: \"#{response_text}\""

      matched_plugin = PluginHandler.handle(bot, user_message, response_text, false)
    end

    if !matched_plugin || !@recognize_plugins
      chat_header = [
        {
          role: 'system',
          content: prompt_header_setup
        }
      ]
      combined_conversation = chat_header + @chat_history

      Logging.log.info 'Sending chat conversation to OpenAI...'
      Logging.log.info "Chat prompt sent:\n#{combined_conversation}" if BotConfig.config['openai']['log_prompts']

      bot.api.sendChatAction(chat_id: user_message.chat.id, action: 'typing')

      response_text = send_chat_prompt(combined_conversation)

      if response_text.match?(%r{.*?(\/.*?)$})
        possible_command = response_text.match(%r{.*?(\/.*?)$})
        nested_matched_plugin = PluginHandler.handle(bot, user_message, possible_command[1], false)
      end

      if !nested_matched_plugin
        bot.api.send_message(chat_id: user_message.chat.id, text: response_text)
      end
    end

    @chat_history.push(
      {
        role: 'assistant',
        content: response_text
      }
    )

    # the number two represents an question by user + answer by chatgpt
    # thus we remove one object for role user and another for role assistant
    2.times { @chat_history.shift } if (@chat_history.size / 2) > BotConfig.config['openai']['max_interaction_history']
  rescue EmptyVoiceMessageException
    Logging.log.error 'Received empty transcription from OpenAI!'
    bot.api.send_message(
      chat_id: user_message.chat.id,
      text: 'Sorry, not sure I caught that, could you repeat it again? ',
      reply_to_message_id: user_message.message_id
    )
  rescue => e
    Logging.log.error "Something went horribly wrong:\n#{e.message}\n#{e.backtrace.join("\n")}"
    bot.api.send_message(
      chat_id: user_message.chat.id,
      text: 'Sorry, feeling a bit dizzy today, could you repeat that again? 😵‍💫',
      reply_to_message_id: user_message.message_id
    )
  end

  private

  def transcribe(file_audio_path)
    response = @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: File.open(file_audio_path, 'rb')
      }
    )

    response['text']
  end

  def send_chat_prompt(conversation)
    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: conversation,
        temperature: 0.5
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def send_interpret_command(user_command_request)
    response = @client.chat(
      parameters: {
        model: 'gpt-4',
        messages: user_command_request,
        temperature: 0
      }
    )

    response.dig('choices', 0, 'message', 'content')
  end

  def prompt_header_setup
    generated_prompt = <<~PROMPT
You are Joshua a helpful chatbot who enjoys chatting with any human who interacts with him.
#{@personality}#{@plugins_list_prompt_segment.empty? ? '' : "\n#{@plugins_list_prompt_segment}\n"}
PROMPT

    generated_prompt.chomp
  end
end
