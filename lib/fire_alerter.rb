require 'redis'
require 'eventmachine'
require 'json'

module FireAlerter
  lib_path = File.expand_path('..', __FILE__)
  $clients = []

  autoload :Semaphore, lib_path + '/semaphore'
  autoload :Listener,  lib_path + '/listener'

  class << self
    def start
      Listener.lights_alert_subscribe!
      Listener.lights_config_subscribe!
      EventMachine.run { EventMachine.start_server('0.0.0.0', 9800, Semaphore) }
    end
  end
end

FireAlerter.start ## Village Mod
