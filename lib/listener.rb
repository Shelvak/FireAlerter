module FireAlerter
  module Listener
    extend self

    ### Send lights
    def lights_alert_subscribe!
      Thread.new { lights_alert_subscribe }
    end

    ### Lights configuration
    def lights_config_subscribe!
      Thread.new { lights_config_subscribe }
    end

    ### Loop between current interventions
    def lights_start_loop_subscribe!
      Thread.new { lights_start_loop_subscribe }
    end

    def lights_stop_loop_subscribe!
      Thread.new { lights_stop_loop_subscribe }
    end

    ### BROADCAST
    # def start_broadcast_subscribe!
    #   puts 'Start Broadcast'
    #   Thread.new { start_broadcast_subscribe }
    # end

    def stop_broadcast_subscribe!
      Thread.new { stop_broadcast_subscribe }
    end

    ### Volume Config
    def volume_config_subscribe!
      Thread.new { volume_config_subscribe }
    end

    ### LCD messages
    def lcd_subscribe!
      Thread.new { lcd_subscribe }
    end

    ### Async console intervention creation
    def curl_subscribe!
      Thread.new { curl_subscribe }
    end

    ### Test welf
    def anything_subscribe!
      Thread.new { anything_subscribe }
    end

    def main_semaphore_subscribe!
      Thread.new { main_semaphore_subscribe }
    end

    #####################
    #### Subscribe method
    #####################
    def lights_start_loop_subscribe
      Helpers.redis.subscribe('interventions:lights:start_loop') do |on|
        on.message do |_, msg|
          begin
            Helpers.log "Start Loop Subscriber: #{msg}"

            Looper.start_lights_looper! if msg == 'start'
          rescue => ex
            Helpers.error 'StartLoop error: ', ex
          end
        end
      end
    end

    def lights_stop_loop_subscribe
      Helpers.redis.subscribe('interventions:lights:stop_loop') do |on|
        on.message do |_, msg|
          begin
            Helpers.log "Stop Loop Subscriber: #{msg}"

            Looper.stop_lights_looper! if msg == 'stop'
          rescue => ex
            Helpers.error 'StopLoop error: ', ex
          end
        end
      end
    end

    def lights_alert_subscribe
      Helpers.redis.subscribe('semaphore-lights-alert') do |on|
        on.message do |_, msg|
          begin
            opts = JSON.parse(msg)
            Helpers.log "Alert Subscriber: #{opts}"
            assign_last_lights_alert(msg)

            send_welf_to_all(opts)
          rescue => e
            Helpers.error 'Alert Subscriber', e
          end
        end
      end
    end

    def lights_config_subscribe
      Helpers.redis.subscribe('configs:lights') do |on|
        on.message do |_, msg|
          begin
            opts = JSON.parse(msg)
            Helpers.log "Config Subscriber: #{opts}"

            send_lights_config_to_all(opts)
          rescue => e
            Helpers.error 'Config Subscriber', e
          end
        end
      end
    end

    def lcd_subscribe
      Helpers.redis.subscribe('lcd-messages') do |on|
        on.message do |_, msg|
          begin
            opts = JSON.parse(msg)
            Helpers.log "LCD Subscriber: #{opts}"

            send_msg_to_lcds(opts)
          rescue => e
            Helpers.error 'LCD Subscriber', e
          end
        end
      end
    end

    # def start_broadcast_subscribe
    #   # The only object for this is clean the clients buffer
    #   # anything that we send for the channel will send the sign
    #   Helpers.redis.subscribe('start-broadcast') do |on|
    #     on.message do
    #       begin
    #         Helpers.log 'Starting Broadcast'

    #         # send_signal_to_start_brodcast!
    #       rescue => e
    #         Helpers.error 'Starting Broadcast', e
    #       end
    #     end
    #   end
    # end

    def stop_broadcast_subscribe
      # The only object for this is clean the clients buffer
      # anything that we send for the channel will send the sign
      Helpers.redis.subscribe('stop-broadcast') do |on|
        on.message do
          begin
            Helpers.log 'Stopping Broadcast'

            # send_signal_to_stop_brodcast!
            force_stop_broadcast!
          rescue => e
            Helpers.error 'Stopping Broadcast', e
          end
        end
      end
    end

    def anything_subscribe
      # The only object for this is clean the clients buffer
      # anything that we send for the channel will send the sign
      Helpers.redis.subscribe('anything') do |on|
        on.message do |_, msg|
          begin
            Helpers.log "Mandando lo que venga #{msg}"

            Client.clients.each { |_, c| c.send(msg) }
          rescue => e
            Helpers.error "Mandando lo que llega #{msg}", e
          end
        end
      end
    end

    def volume_config_subscribe
      # The only object for this is clean the clients buffer
      # anything that we send for the channel will send the sign
      Helpers.redis.subscribe('volume-config') do |on|
        on.message do |_, msg|
          begin
            Helpers.log "Volume config at #{msg}%"

            send_volume_to_lights!(msg)
          rescue => e
            Helpers.error "Volume config at #{msg}%", e
          end
        end
      end
    end

    def curl_subscribe
      Helpers.redis.subscribe('async-curl') do |on|
        on.message do |_, msg|
          begin
            Helpers.log "Curleando #{msg}"

            `curl #{msg}`
          rescue => ex
            Helpers.error 'Fallo la curleada: ', ex
          end
        end
      end
    end

    def main_semaphore_subscribe
      Helpers.redis.subscribe('main_semaphore_change') do |on|
        on.message do |_, msg|
          begin
            opts = JSON.parse(msg)
            Helpers.log "Main semaphore change to: #{opts}"

            send_data_to_main_semaphore main_semaphore_welf(opts)
          rescue => e
            Helpers.error 'Main semaphore', e
          end
        end
      end
    end

    def color_intensity_config_welf(opts)
      kind = opts['kind']

      [
        62, 80, 87, 77,
        color_number_for(opts['color']),
        opts['intensity'],
        bool_to_int(kind == 'stay'),
        bool_to_int(kind == 'day'),
        bool_to_int(kind == 'night'),
        60
      ].map(&:chr).join
    end

    private

    def force_stop_broadcast!
      Helpers.redis.publish('force-stop-broadcast', 'stop it')
    end

    def send_volume_to_lights!(volume)
      sleep 0.2
      msg = ">VOL#{volume.to_i.chr}<"
      Client.lights.each { |c| c.send(msg) }
    end

    def send_msg_to_broadcast_clients(msg)
      Client.lights.each do |client|
        begin
          Helpers.log "Broadcast clients. msg: #{msg} to client: #{client}"
          client.send(msg)
        rescue => e
          Helpers.error "Broadcast clients. EXPLOTO TODO VIEJAAAA #{e}", e
        end
      end
    end

    def send_msg_to_lcds(opts)
      msgs = opts.map do |line, msg|
        case
          when line == 'full'
            ">LCD[#{(' ' * 20) + msg}]<"
          #when line == 'line1' # linea 1 siempre con hora
          #  ">LCD1[#{msg[0..19]}]<"
          when line == 'line2'
            ">LCD2[#{msg[0..19]}]<"
          when line == 'line3'
            ">LCD3[#{msg[0..19]}]<"
          when line == 'line4'
            ">LCD4[#{msg[0..19]}]<"
        end
      end.compact

      Client.lcds.each do |client|
        msgs.each { |msg| client.send(msg) && sleep(1) }
      end
    end

    def send_data_to_lights(msg)
      sleep 0.2 # For multiple messages on the same devise
      Client.lights.each { |client| client.send msg }
    end

    def send_data_to_consoles(msg)
      sleep 0.2 # For multiple messages on the same devise
      Client.console&.send msg
    end

    def send_data_to_main_semaphore(msg)
      if (msc = Client.main_semaphore)
        Helpers.log "Semaforo encontrado, #{msc.to_s} enviando: #{msg}"
        # sleep 0.2 # For multiple messages on the same devise
        msc.send msg
      else
        Helpers.log "Semaforo principa NO encontrado"
      end
    end

    def send_welf_to_all(msg)
      send_data_to_lights lights_welf(msg)
      send_data_to_consoles console_welf(msg)
    end

    def send_lights_config_to_all(msg)
      light_config = color_intensity_config_welf(msg)

      save_last_lights_config(msg)
      send_data_to_lights light_config
    end

    def save_last_lights_config(opts)
      kind = opts['kind']
      kind_key = 'lights-config-' + kind
      color = opts['color']
      value = opts['intensity']

      if (kind_config = Helpers.redis.get(kind_key))
        config = JSON.parse(kind_config)
        config[color] = value
      else
        config = { color => '' }
      end

      Helpers.redis.set(
        kind_key,
        config.to_json
      )
    end

    def assign_last_lights_alert(msg)
      Helpers.redis.set('last_lights_alert', msg)
    end

    # No se usa mas
    # def last_lights_alert
    #   last_lights = Helpers.redis.get('last_lights_alert')
    #   JSON.parse(last_lights) if last_lights.to_s != ''
    # end

    # def resend_last_alert
    #   last_lights = last_lights_alert
    #   send_welf_to_all(last_lights) if last_lights
    # end

    def lights_welf(opts)
      opts['welf'] ||
        [
          62, 65, 76, 83,
          bool_to_int(opts['priority']),
          0,             # dotacion
          0,             # movil
          bool_to_int(opts['red']),
          bool_to_int(opts['green']),
          bool_to_int(opts['yellow']),
          bool_to_int(opts['blue']),
          bool_to_int(opts['white']),
          bool_to_int(opts['trap']),
          bool_to_int(opts['day']),
          bool_to_int(opts['sleep']),
          60
        ].map(&:chr).join
    end

    def console_welf(opts)
      # Cuando los semaforos están en reposo la consola se apaga
      off, semaphore = if opts['sleep']
                         [0, semaphore_last_status]
                       end

      # ">ALCrgybwts<"
      [
        62, 65, 76, 67,
        off ||  bool_to_int(opts['red']),
        off ||  bool_to_int(opts['green']),
        off ||  bool_to_int(opts['yellow']),
        off ||  bool_to_int(opts['blue']),
        off ||  bool_to_int(opts['white']),
        off ||  bool_to_int(opts['trap']),
        semaphore ||  bool_to_int(opts['semaphore']),
        60
      ].map(&:chr).join
    end

    def main_semaphore_welf(opts)
      # >APIB1B2<

      [
        62, 65, 80, 73,
        bool_to_int(opts['semaphore']),
        bool_to_int(opts['hooter']),
        60
      ].map(&:chr).join
    end

    def semaphore_last_status
      Helpers.redis.get('semaphore_is_active') || 0
    end


    def color_number_for(color)
      case color.to_s
        when 'red'    then 1
        when 'green'  then 2
        when 'yellow' then 3
        when 'blue'   then 4
        when 'white'  then 5
      end
    end

    def bool_to_int(bool)
      bool ? 1 : 0
    end
  end
end
