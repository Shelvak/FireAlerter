require 'daemons'

def custom_show_status(app)
  # Display the default status information
  app.default_show_status

  puts
  puts "PS information"
  system("ps -p #{app.pid.pid.to_s}")

  #puts
  #puts "Size of log files"
  #system("du -hs /path/to/logs")
end

Daemons.run(
  File.expand_path('..', __FILE__) + '/lib/fire_alerter.rb',
  { show_status_callback: :custom_show_status }
)
