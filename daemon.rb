require 'daemons'



Daemons.run(File.expand_path('..', __FILE__) + '/lib/fire_alerter.rb')

