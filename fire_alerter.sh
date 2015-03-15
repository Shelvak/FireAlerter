#!/bin/sh
### BEGIN INIT INFO
# Provides:          <NAME>
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       <DESCRIPTION>
### END INIT INFO

ruby=`which ruby`
if test "$(uname)" = "Darwin"; then
  daemon_file="/Users/rotsen/git/firealerter/daemon.rb"
else
  daemon_file="/home/rotsen/rails/firealerter/daemon.rb"
fi
command="$ruby $daemon_file"

start() {
  if running; then
    echo 'Service already running' >&2
    return 1
  fi

  echo 'Starting service…' >&2
  echo `$command start`
  echo 'Service started' >&2
}


stop() {
  if ! running; then
    echo 'Service not running' >&2
    return 1
  fi

  echo 'Stopping service…' >&2
  echo `$command stop`
  echo 'Service stopped' >&2
}

status(){
  echo `$command status`
}

running() {
  echo $command
  if [[ `$command status` =~ \d+ ]];then
    return 0
  else
    return 1
  fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  retart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
esac
