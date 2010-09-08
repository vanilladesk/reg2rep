#!/bin/bash
# ------------------------------------------------
# Simple startup/shutdown script registering/unregistering computer's
# ip address to/from repository. 
#
# It can be used to determine how many and which computers are up.
# This information can be used by e.g. load-balancers.
# 
# (c) 2009-10 Vanilladesk Ltd., http://github.com/vanilladesk/reg2rep
# ------------------------------------------------
#
### BEGIN INIT INFO
# Provides:          reg2rep
# Required-Start:    hostname $network
# Required-Stop:
# Default-Start:	 2 3 4 5
# Default-Stop:      0 1 6     
# Short-Description: Simple repository registration and unregistration for startup and shutdown.
# Description:       Simple repository registration and unregistration for startup and shutdown.
### END INIT INFO
#

# current timestamp
_now="`date +%Y%m%d-%H%M%S`"

# system's ip address
_ip="`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1'| cut -d: -f2 |cut -d' ' -f1`"

# Reg2Rep configuration file to be used
R2R_CONFIG=#PLACEHOLDER

# Repository domain
R2R_DOMAIN=#PLACEHOLDER

# 
R2R_ITEM="$_ip"

# Item attributes in form "key1:value1;key2:value2;...;keyN:valueN"
R2R_ATTRIBUTES="start:$_now;alive:$_now"

RETVAL=0

#-------------------------------------------------

function start() {
  reg2rep -c $R2R_CONFIG --add $R2R_DOMAIN $R2R_ITEM "$R2R_ATTRIBUTES"
}

function stop() {
  reg2rep -c $R2R_CONFIG --delete $R2R_DOMAIN $R2R_ITEM
}

function status() {
  echo "Following servers are listed now:"
  reg2rep -c $R2R_CONFIG --list $R2R_DOMAIN hash
}

#------------------------------------------------

case "$1" in
  start)
        start
		RETVAL=$?
        ;;
  stop)
        stop
		RETVAL=$?
        ;;
  status)
        status
		RETVAL=$?
        ;;
  *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
esac

exit $RETVAL