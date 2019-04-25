module FireAlerter
  module Helpers
    extend self

    def log(string = '')
      logger.info transliterate_the_byte(string)
    rescue => ex
      error(string, ex)
    end

    def error(string, ex=nil)
      ex = string if string.is_a?(Exception)
      report_error(ex)

      logger.error(string)
      if ex
        logger.error(ex)
        logger.error(ex.backtrace.join("\n"))
      end
    end

    def report_error(error)
      ::Bugsnag.notify(error)
    end

    def logger
      @logger ||= begin
                    logger = ::Logger.new(logs_path + '/firealerter.log')
                    logger.formatter = proc do |severity, datetime, progname, msg|
                      "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
                    end
                    logger
                  end
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

    def time_now
      # Argentina Offset
      Time.now.utc - 10800
    end


    def logs_path
      logs = ENV['LOGS_PATH']
      logs ||= if File.writable_real?('/logs')
                 '/logs'
               else
                 File.expand_path('../../logs', __FILE__)
               end
      system("mkdir -p #{logs}")
      logs
    end

    def transliterate_the_byte(string)
      transliterated = ''
      string.each_byte { |b| transliterated += ((0..10).include?(b) ? b : b.chr).to_s }
      transliterated
    end
  end
end
