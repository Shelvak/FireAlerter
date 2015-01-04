module FireAlerter
  module Listener
    class << self

      def lights_alert_subscribe!
        Thread.new { lights_alert_subscribe }
      end

      def lights_config_subscribe!
        Thread.new { lights_config_subscribe }
      end

      def lights_alert_subscribe
        redis.subscribe('semaphore-lights-alert') do |on|
          on.message do |channel, msg|
            opts = JSON.parse(msg)
            Helpers.print "Redis: #{opts}"
            @last_lights_alert = opts

            send_welf_to_all(opts)
          end
        end
      end

      def lights_config_subscribe
        redis.subscribe('configs:lights') do |on|
          on.message do |channel, msg|
            opts = JSON.parse(msg)
            Helpers.print "Redis: #{opts}"

            send_lights_config_to_all(opts)
          end
        end
      end

      private

        def redis
          @redis ||= Redis.new
        end

        def send_data_to_all(msg)
          sleep 0.1 # For multiple messages on the same devise
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
          case color
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
