require 'redis'
require 'eventmachine'
require 'json'

module FireAlerter
  lib_path = File.expand_path('..', __FILE__)
  $clients = []

  autoload :Semaphore,     lib_path + '/semaphore'
  autoload :AlertListener, lib_path + '/alert_listener'

  class << self
    def start
      Thread.new { AlertListener.lights_alert_subscribe }
      EventMachine.run { EventMachine.start_server('0.0.0.0', 9800, Semaphore) }
    end
  end
end

FireAlerter.start ## Village Mod
