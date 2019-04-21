require 'rake'
require 'rubygems'
require 'bundler/setup'
require 'bugsnag-em'

require File.expand_path('../lib/fire_alerter', __FILE__)

desc 'Run tests'
task :test do
  # TBD
end

desc 'Start application [Default]'
task :start do
  Bugsnag.configure do |config|
    config.api_key = '106273f60a3e1fd9dc811c73d1844b2a'
    config.release_stage = 'production'
  end

  FireAlerter.start
end

task default: [:start]
