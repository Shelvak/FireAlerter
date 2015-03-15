require 'redis'
require 'eventmachine'
require 'json'

module FireAlerter
  lib_path = File.expand_path('..', __FILE__)
  $clients = []

  autoload :Semaphore, lib_path + '/semaphore'
  autoload :Listener,  lib_path + '/listener'
  autoload :Helpers,   lib_path + '/helpers'

  class << self
    def start
      puts "1"
      Listener.lights_alert_subscribe!
      sleep 1
      puts "2"
      Listener.lights_config_subscribe!
      sleep 1
      puts "3"
      EventMachine.run { EventMachine.start_server('0.0.0.0', 9800, Semaphore) }
      puts "Andando =)"
    end
  end
end

FireAlerter.start ## Village Mod
