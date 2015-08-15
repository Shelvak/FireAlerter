module FireAlerter
  module DevicesConnection
    require 'pry-nav'

    def post_init
      Helpers.log "#{device_to_s} connected"
    end

    def receive_data(data)
      Helpers.log "#{device_to_s} Receive: #{data}"

      case
        when match_keep_alive?(data)
          send_ok_or_time!

        when match_ok_data?(data)
          nil

        when (presentation = match_presentation(data))
          add_id_to_active_devices! *presentation
          send_ok!

        when (welf = welf_recived?(data))
          treat_welf *welf

        else
          say_hi!
      end
    end

    def unbind
      remove_device_from_active_clients!
    end

    private

      def welf_recived?(data)
        if device_exist? && ( match = data.match(/>CP(\w)(.*)</) )
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

        unless [red, green, yellow, blue, white].all? { |b| b == 0 }
          Helpers.create_intervention(
            {
              red:    red,
              green:  green,
              yellow: yellow,
              blue:   blue,
              white:  white
            }
          )
        end

        send_data '>CPCOK<'
      end

      def binary_to_bool(binary)
        binary == 1
      end

      def treat_special_buttons(welf)
        _trap, semaphore, hooter = *welf.bytes
        p "trap, semaphore, hooter", _trap, semaphore, hooter

        ## do something
        send_data '>CPIOK<'
      end

      def treat_gates(welf)
        gate1, gate2, gate3, gate4 = *welf.bytes
        p "gate 1..4: ", gate1, gate2, gate3, gate4
        puts welf

        ## do something
        send_data '>CPPOK<'
      end

      def match_ok_data?(data)
        device_exist? && data.match(
          /(ALSOK|PWMOK|COK|HORAOK|CPPOK|CPIOK|CPCOK|ALCOK|HORAOK)/
        )
      end

      def match_keep_alive?(data)
        device_exist? &&
        (_regex = keep_alive_regex(device_name)) &&
        (_match = data.match(_regex)) &&
        _match[1] == device_id
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

      def keep_alive_regex(name)
        case name
          when 'SEMAFORO'
            />S\((\d+)\)</

          when 'CONSOLA'
            />C\((\d+)\)</
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
        device ? "(#{ [device.name, device.id].join('-') })" : ''
      end

      def say_hi!
        Helpers.log 'Say Hi'
        send_data '>$?<'
      end

      def send_ok!
        Helpers.log 'Ok'
        send_data '>SOK<'
      end

      def add_id_to_active_devices!(_, name, version, id)
        $clients[self.object_id] = OpenStruct.new(
          id: id,
          name: name,
          version: version,
          connection: self
        )

        Helpers.log "#{device_to_s} added"
        Crons.send_lights_config_to!(device)
      end

      def remove_device_from_active_clients!
        Helpers.log "#{device_to_s} dropped"

        $clients.delete(self.object_id)
      end

      def device_exist?
        $clients.keys.include?(self.object_id)
      end

      def client_timer?
        device_name == 'CONSOLA'
      end

      def send_time!
        Helpers.log 'Timing'
        send_data Helpers.time_now.strftime('>HORA[%H:%m-%d/%m/%Y]<')
      end

      def send_ok_or_time!
        if [true, false].sample && client_timer?
          send_time!
        else
          send_ok!
        end
      end
  end
end
