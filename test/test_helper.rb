require 'test/unit'
require 'byebug'
require 'awesome_print'
require 'bugsnag'

require File.expand_path('../../lib/fire_alerter', __FILE__)

module TestConnectionClient
  def post_init
    send_data $messages.shift
    send_data "\n"
  end

  def receive_data(data)
    close_connection_after_writing if $messages.empty?
    send_data $messages.shift
    send_data "\n"
    close_connection_after_writing if $messages.empty?
  end
end

module TestConnectionServer
  include FireAlerter::DevicesConnection

  def send_data(msg)
    $server_responsed << msg unless msg == "\n"

    super(msg)
  end

  def receive_data(data)
    $server_received << data unless data == "\n"

    super(data)
  end

  def unbind
    EventMachine.stop
  end
end

def send_and_receive!(*messages)
  $start_port     ||= 59801
  $start_port      += 1
  $messages         = messages
  $server_received  = []
  $server_responsed = []

  EventMachine.run {
    EventMachine.start_server '127.0.0.1', $start_port, TestConnectionServer
    EventMachine.connect '127.0.0.1', $start_port, TestConnectionClient
  }

  # Clean clients
  FireAlerter::Client.clients.each do |o_id, e|
    e.connection.close_connection rescue nil
    e.class.remove(o_id)
  end

  results = { received: $server_received, responsed: $server_responsed }
  $server_responsed = $server_received = nil
  results
end
