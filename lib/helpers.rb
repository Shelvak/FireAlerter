module FireAlerter
  module Helpers
    class << self
      def log(string)
        `echo "#{Time.now.strftime('%H:%M:%S')} => #{string}" >> /logs/firealerter.log`
      end

      def error(string, ex)
        msg = [
          Time.now.strftime('%H:%M:%S'),
          string,
          ex.message,
          "\n" + ex.backtrace.join("\n")
        ].join(' => ')

        `echo -en "#{msg}" >> /logs/firealerter.errors`
      end
    end
  end
end
