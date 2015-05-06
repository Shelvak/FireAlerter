require 'rake'
require 'rubygems'
require 'bundler/setup'
require 'redis'
require 'eventmachine'
require 'json'
require 'thread'
require 'bugsnag-em'
require File.expand_path('../lib/fire_alerter', __FILE__)

Bugsnag.configure do |config|
   config.api_key = '106273f60a3e1fd9dc811c73d1844b2a'
   config.release_stage = 'production'
end

FireAlerter.start
