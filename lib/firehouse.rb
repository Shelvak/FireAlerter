module FireAlerter
  module Firehouse
    extend self

    FIREHOUSE_HOST = ENV['SERVER_HOST'].freeze

    def create_intervention(colors)
      return unless colors.values.any?

      Helpers.log(
        'Sending intervention create:' + colors.map { |k, v| [k, v].join(': ') }.join(', ')
      )
      curl_to 'console_create', colors
    end

    def trap_signal!
      Helpers.log 'Sending trap people to last console intervention'
      curl_to 'console_trap_sign'
    end

    def curl_to(path, extras = {})
      args = ['-X' 'GET', "#{FIREHOUSE_HOST}/#{path}"]
      args += extras.map { |k, v| "-d #{k}=#{v}" } if extras.any?
      msg  = args.join(' ')

      Helpers.log "Async firehouse curl #{msg}"
      Helpers.redis.publish('async-curl', msg)
    end
  end
end
