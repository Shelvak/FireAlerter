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
    config.api_key       = ENV['BUGSNAG_KEY']
    config.release_stage = 'production'
  end

  FireAlerter.start
end

desc 'Run Console'
task :console do
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  $stdout.sync = true

  IRB.start
end

task default: [:start]
