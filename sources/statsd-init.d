#! /bin/sh
### BEGIN INIT INFO
# Provides:          statsd
# Required-Start:    $network $local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

# Do NOT "set -e"

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

# For SELinux we need to use 'runuser' not 'su'
SU="/bin/su"

PATH=$PATH:/usr/local/bin:/usr/bin:/bin
NODE_BIN=$(which node||which nodejs)

if [ ! -x "$NODE_BIN" ]; then
  echo "Can't find executable nodejs or node in PATH=$PATH"
  exit 1
fi

NM=/usr/share
S_BASE=${NM}/statsd
LOG_DIR=/var/log
RUN_DIR=/var/run

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="StatsD"
NAME=statsd
DAEMON_ARGS="${S_BASE}/share/statsd/stats.js ${S_BASE}/etc/config.js 2>&1 >> ${LOG_DIR}/statsd.log "
PIDFILE=${S_BASE}/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME
CHDIR="${S_BASE}/share/statsd"
STATSD_USER=root

# Exit if the package is not installed
# [ -x "$DAEMON" ] || exit 0

#
# Function that starts the daemon/service
#
do_start()
{
        # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        daemon --user $STATSD_USER "exec node /usr/share/statsd/stats.js /etc/statsd/config.js  >> ${LOG_DIR}/statsd.log &"
        # Add code here, if necessary, that waits for the process to be ready
        # to handle requests from services started subsequently which depend
        # on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        $SU - $STATSD_USER -c "pkill node"
        RETVAL="$?"
        [ "$RETVAL" = 2 ] && return 2
        return "$RETVAL"
}

# Hack, hack, hack - nic
alias log_daemon_msg=/bin/true
alias log_end_msg=/bin/true

case "$1" in
  start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
        do_start
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
                2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
        esac
        ;;
  restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        log_daemon_msg "Restarting $DESC" "$NAME"
        do_stop
        case "$?" in
          0|1)
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac

