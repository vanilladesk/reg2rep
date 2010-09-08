#!/bin/bash
# ------------------------------------------------
# Simple script for updating information related to registered computer
# in registry. 
#
# Trivial usage is to update "heartbeat" information.
# You can create a simple file in /etc/cron.d containing just one line, e.g.
# 0 * * * *	 root	 <full file name of this file>"
# to run this heartbeat every hour.
# Of course, do not forget to modify placeholders below.
# 
# (c) 2009-10 Vanilladesk Ltd., http://github.com/vanilladesk/reg2rep
# ------------------------------------------------
#

# current date & time
_now="`date +%Y%m%d-%H%M%S`"

# current ip address
_ip="`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1'| cut -d: -f2 |cut -d' ' -f1`"

# Reg2Rep configuration file to be used
R2R_CONFIG=#PLACEHOLDER

# Repository domain
R2R_DOMAIN=#PLACEHOLDER

R2R_ITEM="$_ip"

R2R_ATTRIBUTES="alive:$_now"

reg2rep -c $R2R_CONFIG --update $R2R_DOMAIN $R2R_ITEM "$R2R_ATTRIBUTES"