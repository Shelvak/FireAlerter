module FireAlerter
  module Helpers
    extend self

    def log(string = '')
      write_in_log([
        time_now_to_s,
        transliterate_the_byte(string)
      ].join(' => '))
    rescue => ex
      error(string, ex)
    end

    def error(string, ex=nil)
      ex = string if string.is_a?(Exception)
      report_error(ex)

      write_in_error_log([
        time_now_to_s,
        transliterate_the_byte(string),
        ex.message,
        "\n" + ex.backtrace.join("\n")
      ].join(' => '))
    rescue => ex
      puts ex.backtrace.join("\n")
    end

    def report_error(error)
      puts error
      Bugsnag.notify(error)
    end

    def write_msg_in_file(msg, file)
      File.open(file, 'a') { |f| f.write("#{msg}\n") }
    end

    def write_in_log(msg)
      write_msg_in_file(msg, "#{logs_path}/firealerter.log")
    end

    def write_in_error_log(msg)
      write_msg_in_file(msg, "#{logs_path}/firealerter.errors")
    end

    def redis
      @redis_opts ||= begin
                        opts = {
                          host: ENV['REDIS_HOST'] || ENV['REDIS_PORT_6379_TCP_ADDR'] || 'localhost',
                          port: ENV['REDIS_PORT'] || '6379'
                        }
                        # opts.merge!(password: ENV['REDIS_PASS']) if ENV['REDIS_PASS']
                        opts
                      end

      Redis.new(@redis_opts)
    end

    def time_now_to_s
      time_now.strftime('%H:%M:%S')
    end

    def time_now
      # Argentina Offset
      Time.now.utc - 10800
    end


    def logs_path
      @logs_path ||= begin
                       logs = ENV['LOGS_PATH']
                       logs ||= if File.writable_real?('/logs')
                                  '/logs'
                                else
                                  File.expand_path('../../logs', __FILE__)
                                end
                       system("mkdir -p #{logs}")
                       logs
                     end
    end

    def transliterate_the_byte(string)
      transliterated = ''
      string.each_byte { |b| transliterated += ((0..10).include?(b) ? b : b.chr).to_s }
      transliterated
    end
  end
end
