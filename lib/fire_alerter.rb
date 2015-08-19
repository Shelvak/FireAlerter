module FireAlerter
  $lib_path = File.expand_path('..', __FILE__)
  $clients = {}

  autoload :Helpers,           $lib_path + '/helpers'
  autoload :DevicesConnection, $lib_path + '/devices_connection'
  autoload :Looper,            $lib_path + '/looper'
  autoload :Listener,          $lib_path + '/listener'
  autoload :Crons,             $lib_path + '/crons'

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
      Listener.start_broadcast_subscribe!
      puts "Start Broadcast"
      sleep 1
      Listener.stop_broadcast_subscribe!
      puts "Stop Broadcast"
      puts "Starting server..."
      Helpers.log "Server started"
      EventMachine.run { EventMachine.start_server('0.0.0.0', 9800, DevicesConnection) }
    end
  end
end
