module FireAlerter
  lib_path = File.expand_path('..', __FILE__)
  $clients = []

  autoload :Helpers,   lib_path + '/helpers'
  autoload :Semaphore, lib_path + '/semaphore'
  autoload :Looper,    lib_path + '/looper'
  autoload :Listener,  lib_path + '/listener'

  class << self
    def start
      puts "Subscribing..."
      Listener.lights_alert_subscribe!
      puts "Alerts"
      sleep 1
      Listener.lights_config_subscribe!
      puts "Configs"
      sleep 1
      Listener.lights_start_loop_subscribe!
      puts "Start loop"
      sleep 1
      Listener.lights_stop_loop_subscribe!
      puts "Stop loop"
      sleep 1
      puts "Starting server..."
      Helpers.log "Server started"
      EventMachine.run { EventMachine.start_server('0.0.0.0', 9800, Semaphore) }
    end
  end
end
