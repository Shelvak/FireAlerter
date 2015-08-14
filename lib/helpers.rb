module FireAlerter
  module Helpers
    class << self
      @@logs_path = nil

      def log(string = '')
        begin
          str = transliterate_the_byte(string)
          `echo "#{time_now_to_s} => #{str}" >> #{logs_path}/firealerter.log`
        rescue => ex
          p ex.backtrace.join("\n")
        end
      end

      def error(string, ex)
        begin
          str = transliterate_the_byte(string)
          msg = [
            time_now_to_s,
            str,
            ex.message,
            "\n" + ex.backtrace.join("\n")
          ].join(' => ')

          `echo -en "#{msg}" >> #{logs_path}/firealerter.errors`
        rescue => ex
          p ex.backtrace.join("\n")
        end
      end

      def redis
        Redis.new(host: $REDIS_HOST)
      end

      def time_now_to_s
        time_now.strftime('%H:%M:%S')
      end

      def time_now
        # Argentina Offset
        Time.now.utc - 10800
      end

      def logs_path
        return @@logs_path if @@logs_path

        @@logs_path = ENV['logs_path']
        @@logs_path ||= if File.writable_real?('/logs')
                          '/logs'
                      else
                        logs_path = File.join('..', $lib_path, 'logs')
                        system("mkdir -p #{logs_path}")

                        logs_path
                      end

        p @@logs_path
        @@logs_path
      end

      def transliterate_the_byte(string)
        string.bytes.map { |b| b < 10 ? b : b.chr }.join
      end

      def send_new_intervention_to_app(colors)
        host = ENV['firehouse_host'] || 'localhost:3000'
        uri = URI.parse("http://#{host}/interventions/console_create")
        uri.query = URI.encode_www_form({lights: colors})
        Net::HTTP.get(uri)
      end
    end
  end
end
