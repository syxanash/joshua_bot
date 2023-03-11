# gem "arduino_firmata" first
require 'arduino_firmata'

class MotionSensor < AbsPlugin
  @video_stopped = false

  MOTIONSENSOR_STATE_FILE = '/tmp/motion_sensor.log'

  def command
    /^\/motionsensor (.+?)$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: "type /motionsensor *switch value*\nswitch values: on/off/idle or status to get the current status")
  end

  def do_stuff(match_results)
    switch_value = match_results[1]

    # available commands for this plugin
    status = {
      on: 'on',
      idle: 'idle',
      off: 'off',
      info: 'status'
    }

    # number of signal to ignore from PIR
    # before grabbing photos and video
    max_counter = 2

    # check if commands entered is valid
    unless status.value?(switch_value)
      bot.api.send_message(chat_id: message.chat.id, text: "Can't recognize command #{switch_value} for Motion Sensor plugin!")
      return 0 # quit current plugin session
    end

    # check if user wants to get the status of the plugin
    if switch_value == status[:info]
      current_status = status[:off]

      if File.exist? MOTIONSENSOR_STATE_FILE
        current_status = File.read(MOTIONSENSOR_STATE_FILE)
      end

      bot.api.send_message(chat_id: message.chat.id, text: "Motion Sensor plugin currently #{current_status}!")
      return 0
    end

    # If the plugin log file exist, it means that the plugin was already started
    # in this case we only change the value of the plugin to on/idle/off
    # otherwise we write a log file for the first time
    if File.exist? MOTIONSENSOR_STATE_FILE
      File.write(MOTIONSENSOR_STATE_FILE, switch_value)
      bot.api.send_message(chat_id: message.chat.id, text: "Motion Sensor mode changed to #{switch_value}")

      return 0 # quit the current plugin call
    else
      # writing the switch value for the first time after creating the file
      File.write(MOTIONSENSOR_STATE_FILE, switch_value)
    end

    # get the initial value for the plugin process
    plugin_process = switch_value

    arduino = ArduinoFirmata.connect

    pir = 7
    led_pin = 12
    pir_state = false

    counter = 0

    arduino.pin_mode pir, ArduinoFirmata::INPUT

    boot_screen_text = <<-FOO
##########
Arduino Firmata version #{arduino.version}
LED on port: #{led_pin}
PIR sensor on port: #{pir}
##########
FOO

    puts boot_screen_text
    bot.api.send_message(chat_id: message.chat.id, text: 'Arduino Motion Sensor up and running!')

    while plugin_process != status[:off]
      pir_state = arduino.digital_read pir
      puts "[?] PIR state: #{pir_state}"
      arduino.digital_write led_pin, pir_state

      if plugin_process == status[:on]
        if pir_state
          counter += 1
        else
          counter = 0
        end

        if counter >= max_counter
          # remove comment in following line if you want
          # to scare to death the thief
          system('mpg123 other/media/alert.mp3')

          threads = []

          threads << Thread.new { take_video() }
          threads << Thread.new { take_photo() }

          threads.each { |t| t.join }

          puts '[?] resetting counter...'

          counter = 0
        end
      elsif plugin_process == status[:idle]
        if pir_state
          system('mpg123 other/media/welcome.mp3')

          arduino.digital_write led_pin, false
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

    # close arduino firmata connection and remove configuration
    # file for the plugin thread
    arduino.close
    File.delete(MOTIONSENSOR_STATE_FILE)

    puts '[?] Motion Sensor plugin daemon deleted!'
    bot.api.send_message(chat_id: message.chat.id, text: 'Motion Sensor plugin turned off!')
  end

  def take_video(seconds = 20)
    fail Exception, 'must give from 1 to 69 seconds!' if seconds > 60

    temp_name = "#{Time.now.to_i}_spy_video"

    system("streamer -q -c /dev/video0 -f rgb24 -r 3 -t 00:00:#{seconds} -o #{temp_name}.avi")
    system("ffmpeg -i #{temp_name}.avi -acodec libfaac -b:a 128k -vcodec mpeg4 -b:v 1200k -flags +aic+mv4 #{temp_name}.mp4")

    bot.api.sendVideo(chat_id: message.chat.id, video: Faraday::UploadIO.new(temp_name + '.mp4', 'video/mp4'))
    File.delete(temp_name + '.mp4', temp_name + '.avi') 

  ensure 
    @video_stopped = true
  end

  def take_photo
    photo_per_seconds = 1

    until @video_stopped
      temp_name = "#{Time.now.to_i}_spy_photo.jpg"

      system("fswebcam --save #{temp_name} -d /dev/video1 --skip 30 -r 640x480")

      bot.api.sendPhoto(chat_id: message.chat.id, photo: Faraday::UploadIO.new(temp_name, 'image/jpeg'))
      File.delete(temp_name)

      sleep(photo_per_seconds)
    end

    @video_stopped = false
  end
end
