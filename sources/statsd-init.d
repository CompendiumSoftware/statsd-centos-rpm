#! /bin/sh
### BEGIN INIT INFO
# Provides:          statsd
# Required-Start:    $network $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

. /etc/rc.d/init.d/functions

prog=statsd
STATSDDIR=/usr/share/statsd
statsd=./stats.js
LOG=/var/log/statsd.log
ERRLOG=/var/log/statsderr.log
CONFFILE=/etc/statsd/config.js
pidfile=/var/run/statsd.pid
lockfile=/var/lock/subsys/statsd
RETVAL=0
STOP_TIMEOUT=${STOP_TIMEOUT-10}

start() {
  echo -n $"Starting $prog: "
  cd ${STATSDDIR}

  # See if it's already running. Look *only* at the pid file.
  if [ -f ${pidfile} ]; then
    failure "PID file exists for statsd"
    RETVAL=1
  else
    # Run as process
    node ${statsd} ${CONFFILE} >> ${LOG} 2>> ${ERRLOG} &
    RETVAL=$?

    # Store PID
    echo $! > ${pidfile}

    # Success
    [ $RETVAL = 0 ] && success "statsd started"
  fi

  echo
  return $RETVAL
}

stop() {
  echo -n $"Stopping $prog: "
  killproc -p ${pidfile}
  RETVAL=$?
  echo
  [ $RETVAL = 0 ] && rm -f ${pidfile}
}

# See how we were called.
case "$1" in
  start)
  start
  ;;
  stop)
  stop
  ;;
  status)
  status -p ${pidfile} ${prog}
  RETVAL=$?
  ;;
  restart)
  stop
  start
  ;;
  condrestart)
  if [ -f ${pidfile} ] ; then
    stop
    start
  fi
  ;;
  *)
  echo $"Usage: $prog {start|stop|restart|condrestart|status}"
  exit 1
esac

exit $RETVAL