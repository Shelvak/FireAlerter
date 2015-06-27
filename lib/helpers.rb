module FireAlerter
  module Helpers
    class << self
      @@logs_path = nil

      def log(string = '')
        begin
          `echo "#{time_now} => #{string.to_s}" >> #{logs_path}/firealerter.log`
        rescue => ex
          p ex.backtrace.join("\n")
        end
      end

      def error(string, ex)
        begin
          msg = [
            time_now,
            string,
            ex.message,
            "\n" + ex.backtrace.join("\n")
          ].join(' => ')

          `echo -en "#{msg}" >> #{logs_path}/firealerter.errors`
        rescue => ex
          p ex.backtrace.join("\n")
        end
      end

      def time_now
        # Argentina Offset
        (Time.now.utc - 10800).strftime('%H:%M:%S')
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
      end
    end
  end
end
