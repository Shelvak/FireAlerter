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
            Helpers.print "Redis: #{msg}"

            Loop.start_lights_looper! msg == 'start'
          end
        end
      end

      def lights_stop_loop_subscribe
        redis.subscribe('interventions:lights:stop_loop') do |on|
          on.message do |channel, msg|
            Helpers.print "Redis: #{msg}"

            Looper.stop_lights_looper! if msg == 'stop'
          end
        end
      end

      def lights_alert_subscribe
        redis.subscribe('semaphore-lights-alert') do |on|
          begin
          on.message do |channel, msg|
            begin
              opts = JSON.parse(msg)
              Helpers.print "Redis: #{opts}"
              @last_lights_alert = opts

              send_welf_to_all(opts)
            rescue => e
              p "alert adentro => ", e
            end
          end
          rescue => e
            p "alert ", e
          end
        end
      end

      def lights_config_subscribe
        redis.subscribe('configs:lights') do |on|
          begin
            on.message do |channel, msg|
              begin
                opts = JSON.parse(msg)
                Helpers.print "Redis: #{opts}"

                send_lights_config_to_all(opts)
              rescue => e
                p "adentro config => ", e
              end
            end
          rescue => e
            p "config => ", e
          end
        end
      end

      private

        def redis
          Redis.new(host: $REDIS_HOST)
        end

        def send_data_to_all(msg)
          sleep 0.5 # For multiple messages on the same devise
          $clients.each { |client| client.send_data msg}
        end

        def send_welf_to_all(msg)
          send_data_to_all welf(msg)
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

        def welf(opts)
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

        def config(opts)
          kind = opts['kind']

          a = [
            62, 80, 87, 77,
            color_number_for(opts['color']),
            opts['intensity'],
            bool_to_int(kind == 'stay'),
            bool_to_int(kind == 'day'),
            bool_to_int(kind == 'night'),
            60
          ].map(&:chr).join
          Helpers.print a
          a
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
