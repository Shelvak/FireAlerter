require 'eventmachine'
require 'json'
require 'net/http'
require 'redis'
require 'thread'
require File.expand_path('../ruby_hacks', __FILE__)

module FireAlerter
  extend self
  LIB_PATH    = File.expand_path('..', __FILE__)

  $clients     = {}
  $stdout.sync = true

  autoload :Client,            LIB_PATH + '/client'
  autoload :Helpers,           LIB_PATH + '/helpers'
  autoload :Firehouse,         LIB_PATH + '/firehouse'
  autoload :DevicesConnection, LIB_PATH + '/devices_connection'
  autoload :Looper,            LIB_PATH + '/looper'
  autoload :Listener,          LIB_PATH + '/listener'
  autoload :Crons,             LIB_PATH + '/crons'

  def start
    puts 'Subscribing...'

    init_alert_and_config
    init_looper
    init_broadcast
    init_extras

    puts 'Starting server...'
    Helpers.log 'Server started'
    init_devices_connection
  end

  def init_devices_connection(port=9800)
    EventMachine.run {
      EventMachine.start_server('0.0.0.0', port, DevicesConnection)
    }
  end

  def init_broadcast
    # Listener.start_broadcast_subscribe!
    # sleep 1
    Listener.stop_broadcast_subscribe!
    sleep 1
  end

  def init_looper
    Listener.lights_start_loop_subscribe!
    sleep 1
    Listener.lights_stop_loop_subscribe!
    sleep 1
  end

  def init_alert_and_config
    Listener.lights_alert_subscribe!
    sleep 1
    Listener.lights_config_subscribe!
    sleep 1
    Listener.volume_config_subscribe!
    sleep 1
    Listener.lcd_subscribe!
    sleep 1
    Listener.main_semaphore_subscribe!
    sleep 1
  end

  def init_extras
    Listener.curl_subscribe!
    sleep 1
    Listener.anything_subscribe!
    sleep 1
  end
end
