class WhoIsHome < AbsPlugin
  def command
    /^\/whoishome$/
  end

  def show_usage
    bot.api.send_message(chat_id: message.chat.id, text: 'type /whoishome')
  end

  def stored_devices
    # change the following file name which contains your mac address alias list
    saved_address_file = 'other/mac_devices.json'

    if File.file?(saved_address_file)
      mac_devices_file_content = File.read(saved_address_file)
      mac_devices_stored = JSON.parse(mac_devices_file_content)
    else
      mac_devices_stored = JSON.parse('{}')
    end

    mac_devices_stored
  end

  def active_devices
    # change the following string if you have a different network interface
    scan_cmd = `arp-scan --retry=8 --ignoredups -I wlan0 --localnet`
    output_lines = scan_cmd.split("\n")

    active_mac_list = []

    # removing useless lines from arp-scan output
    address_lines = output_lines.slice(2, output_lines.size - 5)

    address_lines.each do |line|
      address_data = line.split("\t")
      active_mac_list.push(address_data)
    end

    active_mac_list
  end

  def inclues_mac(address_list, mac_address)
    address_list.each do |address|
      if address == mac_address
        return true
      end
    end

    return false
  end

  def do_stuff(_match_results)

    # check if user wants to get the status of the plugin
    Logging.log.info 'Invoked WhoIsHome plugin for a quick scan...'

    bot.api.send_message(
      chat_id: message.chat.id,
      text: '📡 Scanning the network... '
    )

    devices_stored_list = stored_devices
    devices_found = active_devices

    output_message = ''

    devices_found.each do |device|
      is_saved = false
      should_display = true
      devices_stored_list.each do |stored_device|
        if device[1].upcase == stored_device['mac'].upcase
          is_saved = true
          should_display = stored_device['display']

          if should_display
            output_message += "✅ #{stored_device['name']} is online\n"
          end
        end
      end

      unless is_saved
        output_message += "⚠️ #{device[1]}\t#{device[2]}\n"
      end
    end

    bot.api.send_message(chat_id: message.chat.id, text: output_message)
  end
end
