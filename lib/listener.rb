module FireAlerter
  module Listener
    class << self

      def lights_alert_subscribe!
        Thread.new { lights_alert_subscribe }
      end

      def lights_config_subscribe!
        Thread.new { lights_config_subscribe }
      end

      def lights_start_loop_subscribe!
        Thread.new { lights_start_loop_subscribe }
      end

      def lights_stop_loop_subscribe!
        Thread.new { lights_stop_loop_subscribe }
      end

      def lights_start_loop_subscribe
        redis.subscribe('interventions:lights:start_loop') do |on|
          on.message do |channel, msg|
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
        redis.subscribe('interventions:lights:stop_loop') do |on|
          on.message do |channel, msg|
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
        redis.subscribe('semaphore-lights-alert') do |on|
          on.message do |channel, msg|
            begin
              opts = JSON.parse(msg)
              Helpers.log "Alert Subscriber: #{opts}"
              @last_lights_alert = opts

              send_welf_to_all(opts)
            rescue => e
              Helpers.error 'Alert Subscriber', e
            end
          end
        end
      end

      def lights_config_subscribe
        redis.subscribe('configs:lights') do |on|
          on.message do |channel, msg|
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

      private

        def redis
          Redis.new(host: $REDIS_HOST)
        end

        def send_data_to_lights(msg)
          sleep 0.5 # For multiple messages on the same devise
          light_clients.each { |client| client.connection.send_data msg }
        end

        def send_data_to_consoles(msg)
          sleep 0.5 # For multiple messages on the same devise
          console_clients.each { |client| client.connection.send_data msg }
        end

        def light_clients
          $clients.map { |id, c| c if c.name == 'SEMAFORO' }.compact
        end

        def console_clients
          $clients.map { |id, c| c if c.name == 'CONSOLA' }.compact
        end

        def send_welf_to_all(msg)
          send_data_to_lights lights_welf(msg)
          send_data_to_consoles console_welf(msg)
        end

        def send_lights_config_to_all(msg)
          send_data_to_all config(msg)
          resend_last_alert
        end

        def resend_last_alert
          if @last_lights_alert
            send_welf_to_all(@last_lights_alert)
          end
        end

        def lights_welf(opts)
          opts['welf'] ||
          [
            62, 65, 76, 83,
            0,             # prioridad
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
          # ">ALCrgybwts<"
          [
            62, 65, 76, 67,
            bool_to_int(opts['red']),
            bool_to_int(opts['green']),
            bool_to_int(opts['yellow']),
            bool_to_int(opts['blue']),
            bool_to_int(opts['white']),
            bool_to_int(opts['trap']),
            bool_to_int(opts['semaphore']),
            60
          ].map(&:chr).join
        end


        def config(opts)
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
end
