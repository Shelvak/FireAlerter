require 'rake'
require 'rubygems'
require 'bundler/setup'
require 'redis'
require 'eventmachine'
require 'json'
require 'thread'
require 'bugsnag-em'
require 'pry-nav'
require 'net/http'
require File.expand_path('../lib/ruby_hacks', __FILE__)
require File.expand_path('../lib/fire_alerter', __FILE__)

Bugsnag.configure do |config|
   config.api_key = '106273f60a3e1fd9dc811c73d1844b2a'
   config.release_stage = 'production'
end

$REDIS_HOST = ENV['REDIS_PORT_6379_TCP_ADDR'] || 'localhost'
$FIREHOUSE_HOST = ENV['SERVER_HOST'] || 'localhost'

FireAlerter.start
