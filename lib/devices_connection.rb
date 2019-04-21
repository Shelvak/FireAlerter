module FireAlerter
  module DevicesConnection
    def post_init
      Helpers.log "#{device_to_s} connected"
    end

    def receive_data(data)
      Helpers.log "#{device_to_s} Receive: #{data}"

      case
        when match_keep_alive?(data)
          send_ok_or_time!

        when match_ok_data?(data), match_invalid_data?(data)
          nil

        when (presentation = match_presentation(data))
          add_id_to_active_devices!(*presentation)
          send_ok!

        when (welf = welf_recived?(data))
          treat_welf(*welf)

        else
          say_hi!
      end
    end

    def unbind
      remove_device_from_active_clients!
    end

  private

    def welf_recived?(data)
      if device_exist? && (match = data.match(/>CP(\w)(.*)</))
        match
      end
    end

    def treat_welf(_, dev, welf)
      case dev
        when 'C' then treat_lights_welf(welf)
        when 'I' then treat_special_buttons(welf)
        when 'P' then treat_gates(welf)
      end
    end

    def treat_lights_welf(welf)
      red, green, yellow, blue, white = *welf.bytes.map { |b| binary_to_bool(b) }

      Helpers.log(
        'Sending intervention create:' + {
          red: red, green: green, yellow: yellow, blue: blue, white: white
        }.map { |k, v| [k, v].join(': ') }.join(', ')
      )
      if [red, green, yellow, blue, white].any?
        Helpers.create_intervention(
          red:    red,
          green:  green,
          yellow: yellow,
          blue:   blue,
          white:  white
        )
      end

      respond_with '>CPCOK<'
    end

    def binary_to_bool(binary)
      binary.to_i == 1
    end

    def semaphore_timeout
      Helpers.redis.get('configs:semaphore:timeout') || 20
    end

    def treat_special_buttons(welf)
      Helpers.log("Special welf #{welf} #{welf.bytes}")
      trap_signal, semaphore, hooter = *welf.bytes.map { |b| binary_to_bool(b) }
      Helpers.log "trap: #{trap_signal}, semaphore: #{semaphore} , hooter: #{hooter}"

      if trap_signal
        Helpers.log 'Sending trap people to last console intervention'
        Firehouse.trap_signal!
      end

      if semaphore
        timeout = semaphore_timeout
        Helpers.redis.setex('semaphore_is_active', timeout, 1)
        timeout = '%03d' % timeout

        respond_with ">TSEM#{timeout}<", 'Semaphore signal'
      end

      if hooter
        Helpers.log "Hooter signal.... NOT IMPLEMENTED"
      end

      if hooter || semaphore
        Helpers.log "Sending change to main semaphore"
        Helpers.redis.publish('main_semaphore_change', { semaphore: semaphore, hooter: hooter }.to_json)
      end

      respond_with '>CPIOK<', 'Special signal'
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
      respond_with '>CPPOK<', 'Gates'
    end

    def match_ok_data?(data)
      device_exist? && data.match(/ok<$/i)
    end

    def match_invalid_data?(data)
      invalid = device_exist? && data.match(/invalid/i)
      Helpers.log "Invalid welf from: #{device_name} => #{data}" if invalid
      invalid
    end

    def match_keep_alive?(data)
      device_exist? &&
        (regex = keep_alive_regex(device_name)) &&
        (match = data.match(regex)) &&
        match[1] == device_id
    end

    def match_presentation(data)
      data.match(presentation_regex)
    end

    def presentation_regex
      # >#SEMAPHORE[V1.0.0]-(002)<
      # [1: Name, 2: Version, 3: ID]
      # [1: SEMAPHORE, 2: 1.0.0, 3: 002]
      />#(\w+)\[V(\d+\.\d+.\d+)\]-\((\d{3})\)</
    end

    def keep_alive_regex
      case
        when semaphore? then />S\((\d+)\)</
        when console?   then />C\((\d+)\)</
      end
    end

    def device_name
      $clients[self.object_id].try(:name)
    end

    def device_id
      $clients[self.object_id].try(:id)
    end

    def device
      $clients[self.object_id]
    end

    def device_to_s
      device ? "(#{[device.name, device.id].join('-')})" : ''
    end

    def say_hi!
      respond_with '>$?<', 'Say hi'
    end

    def send_ok!
      respond_with (console? ? '>COK<' : '>SOK<'), 'Ok'
    end

    def add_id_to_active_devices!(_, name, version, id)
      $clients[self.object_id] = OpenStruct.new(
        id:         id,
        name:       name,
        version:    version,
        connection: self
      )

      Helpers.log "#{device_to_s} added"
      Crons.send_init_config_to!(device)
    end

    def remove_device_from_active_clients!
      Helpers.log "#{device_to_s} dropped"

      $clients.delete(self.object_id)
    end

    def device_exist?
      $clients.keys.include?(self.object_id)
    end

    def console?
      device_name == 'CONSOLA'
    end

    def semaphore?
      device_name == 'SEMAFORO'
    end

    def send_time!
      respond_with Helpers.time_now.strftime('>HORA[%H:%M:%S-%d/%m/%Y]<'), 'Timing'
    end

    def send_ok_or_time!
      console? && ((rand * 10) > 7) ? send_time! : send_ok!
    end

    def respond_with(msg, extra = nil)
      Helpers.log "Responding #{extra}: #{msg}"
      send_data msg
    end
  end
end
