module FireAlerter
  module DevicesConnection
    # >#SEMAPHORE[V1.0.0]-(002)<
    # [1: Name, 2: Version, 3: ID]
    # [1: SEMAPHORE, 2: 1.0.0, 3: 002]
    PRESENTATION_REGEX = />#(\w+)\[V(\d+\.\d+.\d+)\]-\((\d{3})\)</

    def post_init
      Helpers.log "#{device.to_s} connected"
    end

    def receive_data(data)
      Helpers.log "#{device&.to_s} Received: #{data}"

      # Ensure device is presented or quit
      unless device
        Helpers.log 'Asking for presentation, >$?<'
        send_data '>$?<'
        return
      end


      case
        when match_keep_alive?(data)
          device.send_ok!

        when match_ok_data?(data), match_invalid_data?(data)
          nil

        when (presentation = match_presentation?(data))
          add_id_to_active_devices!(*presentation)

        when (welf = welf_recived?(data))
          treat_welf(*welf)

        else
          msg = [
            'UN-HANDLED DATA RECEIVED',
            device.to_s,
            data
          ].join(' - ')
          Helpers.log msg
          report_error(msg)

          nil
      end
    end

    def unbind
      remove_device_from_active_clients!
    end

    private

    ############################################################################
    # DATA MATCHERS
    ############################################################################
    def match_ok_data?(data)
      data.match?(/ok<$/i)
    end

    def match_invalid_data?(data)
      invalid = data.match?(/invalid/i)
      Helpers.log "Invalid welf from: #{device&.name} => #{data}" if invalid
      invalid
    end

    def match_keep_alive?(data)
      (regex = device.keep_alive_regex) &&
        (match = data.match(regex)&.captures) &&
        match.first == device.id
    end

    def match_presentation?(data)
      data.match(PRESENTATION_REGEX)&.captures
    end

    def welf_recived?(data)
      data.match(/>CP(\w)(.*)</)&.captures
    end

    ############################################################################
    # WELF HANDLERS
    ############################################################################
    def treat_welf(dev, welf)
      case dev
        when 'C' then treat_lights_welf(welf)
        when 'I' then treat_special_buttons(welf)
        when 'P' then treat_gates(welf)
      end
    end

    def welf_to_bool_list(welf)
      welf.bytes.map { |b| b.to_i == 1 }
    end

    def treat_lights_welf(welf)
      red, green, yellow, blue, white = *welf_to_bool_list(welf)

      Firehouse.create_intervention(
        red:    red,
        green:  green,
        yellow: yellow,
        blue:   blue,
        white:  white
      )

      device.send '>CPCOK<'
    end

    def treat_special_buttons(welf)
      trap_signal, semaphore, hooter = *welf_to_bool_list(welf)
      Helpers.log "Special welf => trap: #{trap_signal}, semaphore: #{semaphore} , hooter: #{hooter}"

      Firehouse.trap_signal! if trap_signal

      device.send_special_semaphore_signal! if semaphore

      Helpers.log "Hooter signal.... NOT IMPLEMENTED" if hooter

      if hooter || semaphore
        Helpers.log "Sending change to main semaphore"
        Helpers.redis.publish('main_semaphore_change', { semaphore: semaphore, hooter: hooter }.to_json)
      end

      device.send '>CPIOK<', 'Special signal'
    end

    def treat_gates(welf)
      gate1, gate2, gate3, gate4 = *welf.bytes
      Helpers.log "NOT IMPLEMENTED Gates: 1: #{gate1}, 2: #{gate2}, 3: #{gate3}, 4: #{gate4}, "
      # Llega CPP
      # Estados 1 2 y 3
      # 1 para la derecha [pro-reloj] | abrir
      # 2 en el medio | reposo
      # 3 para la izq [contra reloj] | cerrar

      ## do something
      device.send '>CPPOK<', 'Gates'
    end

    ############################################################################
    # DEVICE METHODS
    ############################################################################
    def device
      Client.find(self.object_id)
    end

    def add_id_to_active_devices!(name, version, id)
      Client.add(self, id, name, version)

      device.send_ok!

      Crons.send_init_config_to!(device)
    end

    def remove_device_from_active_clients!
      Client.remove(self.object_id)
    end
  end
end
