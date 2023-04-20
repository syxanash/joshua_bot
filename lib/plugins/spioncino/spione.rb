# This plugin also requires avconv, streamer
# sudo apt-get install libav-tools streamer

class Spione < AbsPlugin
  MOTIONSENSOR_STATE_FILE = "#{BotConfig.config['temp_directory']}/motion_sensor.log"
  SENSOR_OUTPUT_FILE = "#{BotConfig.config['temp_directory']}/sensor_output.txt"
  THRESHOLD_FILE = "#{BotConfig.config['temp_directory']}/threshold_sensitivity.txt"

  # number of signal to ignore from PIR
  # before grabbing photos and video
  DEFAULT_SIGNAL_THRESHOLD = 7

  def initialize
    if File.exist? THRESHOLD_FILE
      @signal_threshold = File.read(THRESHOLD_FILE).to_i
    else
      File.write(THRESHOLD_FILE, DEFAULT_SIGNAL_THRESHOLD)
      @signal_threshold = DEFAULT_SIGNAL_THRESHOLD
    end
  end

  def command
    /^\/spione (.+?)$/
  end

  def examples
    [
      { command: '/spione on', description: 'turn on motion sensor to start spying the room' },
      { command: '/spione off', description: 'turn off motion sensor to stop spying the room' }
    ]
  end

  def show_usage
    system("wget https://i.imgur.com/60mdxrh.png -O scheme.png")
    bot.api.send_message(chat_id: message.chat.id, text: "This plugin will work on a Raspberry Pi 🍓\n\ntype /spione *switch value*\nswitch values: on/off/idle/status or status to get the current status")
    bot.api.send_photo(chat_id: message.chat.id, photo: Faraday::UploadIO.new('scheme.png', 'image/png'))
    bot.api.send_message(chat_id: message.chat.id, text: 'To change Motion Sensor sensitivity: /spione inc or dec')
    File.delete('scheme.png')
  end

  def do_stuff(match_results)
    argv_parameter = match_results[1]

    # available commands for this plugin
    status = {
      on: 'on',
      idle: 'idle',
      off: 'off',
      info: 'status'
    }

    # check if argv is for decreasing or increasing sensitivity of motion sensor
    case argv_parameter
    when 'inc'
      @signal_threshold += 1
      File.write(THRESHOLD_FILE, @signal_threshold)
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Motion Sensor sensitivity increased to #{@signal_threshold}"
      )
      return 0
    when 'dec'
      @signal_threshold -= 1
      File.write(THRESHOLD_FILE, @signal_threshold)
      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Motion Sensor sensitivity decreased to #{@signal_threshold}"
      )
      return 0
    end

    # check if commands entered is valid
    unless status.value?(argv_parameter)
      bot.api.send_message(chat_id: message.chat.id, text: "Can't recognize command #{argv_parameter} for Motion Sensor plugin!")
      return 0 # quit current plugin session
    end

    # check if user wants to get the status of the plugin
    if argv_parameter == status[:info]
      current_status = status[:off]

      if File.exist? MOTIONSENSOR_STATE_FILE
        current_status = File.read(MOTIONSENSOR_STATE_FILE)
      end

      bot.api.send_message(
        chat_id: message.chat.id,
        text: "Motion Sensor plugin currently: #{current_status}\nSensitivity set to: #{@signal_threshold}"
      )

      return 0
    end

    # If the plugin log file exist, it means that the plugin was already started
    # in this case we only change the value of the plugin to on/idle/off
    # otherwise we write a log file for the first time
    if File.exist? MOTIONSENSOR_STATE_FILE
      File.write(MOTIONSENSOR_STATE_FILE, argv_parameter)
      bot.api.send_message(chat_id: message.chat.id, text: "Motion Sensor mode changed to #{argv_parameter}")

      return 0 # quit the current plugin call
    else
      # writing the switch value for the first time after creating the file
      File.write(MOTIONSENSOR_STATE_FILE, argv_parameter)
    end

    unless File.exist? SENSOR_OUTPUT_FILE
      puts '[?] creating Pi Motion sensor output file'
      File.write(SENSOR_OUTPUT_FILE, '')
    end

    # get the initial value for the plugin process
    plugin_process = argv_parameter

    # put in a separate thread the python script which checks the PIR sensor
    Thread.new {
      @script_pid = IO.popen("python utils/sensor_script.py #{SENSOR_OUTPUT_FILE}").pid
    }

    counter = 0

    bot.api.send_message(chat_id: message.chat.id, text: '🍓 Pi Motion Sensor up and running!')

    while plugin_process != status[:off]
      pir_state = File.read(SENSOR_OUTPUT_FILE)
      puts "[?] PIR state: #{pir_state}"

      if plugin_process == status[:on]
        if pir_state == '1'
          counter += 1
        else
          counter = 0
        end

        if counter >= @signal_threshold

          tries = 3

          begin
            take_video(5)
            take_video(5)
            take_video(4)
            take_video()
          rescue
            if (tries -= 1) >= 0
              sleep 3
              retry
            else
              puts '[!] SOMETHING WRONG HAPPENED WITH DEVICE!'
            end
          end

          puts '[?] resetting counter...'

          counter = 0
        end
      elsif plugin_process == status[:idle]
        if pir_state == '1'
          take_photo(1)

          break
        end
      else
        puts '[!] Can\'t match any status you entered!'
      end

      # before repeating the loop, read if motionsensor state
      # has changed while running the plugin then wait 1 second
      plugin_process = File.read(MOTIONSENSOR_STATE_FILE)

      sleep 1
    end

    # kill the python script
    Process.kill(15, @script_pid)
    Process.wait(@script_pid)

    # remove configuration file for the plugin thread
    # and motionsensor output
    File.delete(MOTIONSENSOR_STATE_FILE)
    File.delete(SENSOR_OUTPUT_FILE)

    puts '[?] Motion Sensor plugin daemon deleted!'
    bot.api.send_message(chat_id: message.chat.id, text: 'Motion Sensor plugin turned off!')
  end

  def take_photo(num = 5)
    num.times do
      photo_file_name = "#{BotConfig.config['temp_directory']}/spy_photo.jpg"
      system("raspistill -o #{photo_file_name} -w 2592 -h 1944")

      bot.api.sendPhoto(chat_id: message.chat.id, photo: Faraday::UploadIO.new(photo_file_name, 'image/jpeg'), protect_content: true)
      File.delete(photo_file_name)
    end
  end

  def take_video(seconds = 10)
    fail Exception, 'must give from 1 to 69 seconds!' if seconds > 60

    temp_name = "#{BotConfig.config['temp_directory']}/#{Time.now.to_i}_spy_video"

    system("raspivid -o #{temp_name}.h264 -w 1280 -h 720 -t #{seconds}000")
    system("MP4Box -add #{temp_name}.h264 #{temp_name}.mp4")

    bot.api.sendVideo(chat_id: message.chat.id, video: Faraday::UploadIO.new("#{temp_name}.mp4", 'video/mp4'), protect_content: true)

    File.delete("#{temp_name}.h264", "#{temp_name}.mp4")
  end
end
