module FireAlerter
  module AlertListener
    class << self
      def lights_alert_subscribe
        redis.subscribe('semaphore-lights-alert') do |on|
          on.message do |channel, msg|
            opts = JSON.parse(msg)
            print "Redis: #{opts}"

            send_welf_to_all(opts)
          end
        end
      end

      private

        def redis
          @redis ||= Redis.new
        end

        def send_welf_to_all(msg)
          $clients.each { |client| client.send_data welf(msg) }
        end

        def welf(opts)
          opts['welf'] ||
          [
            62, 65, 76, 83,
            0,             # prioridad
            0,             # dotacion
            0,             # movil
            (opts['red']    ? 1 : 0),
            (opts['green']  ? 1 : 0),
            (opts['yellow'] ? 1 : 0),
            (opts['blue']   ? 1 : 0),
            (opts['white']  ? 1 : 0),
            (opts['trap']   ? 1 : 0),
            (opts['day']    ? 1 : 0),
            (opts['sleep']  ? 1 : 0),
            60
          ].map(&:chr).join
        end
    end
  end
end
