#!/bin/bash
 
#
# Network Uptime Monitor v0.2
# Copyright 2016 Danoz <danoz@danoz.net>
#
 
# User variables
# you can change these to values that suit.
 
# change these to your preferred DNS Servers/or IP's of interest to pint
IP=( "8.8.8.8" "4.2.2.2" "208.67.222.222" )
# set test interval to every X seconds
TESTINT="1"
# mark as failure after X seconds of outage
LOGFAIL="5"
# adjust as necessary for your environment.
# ubiquiti routers need the path specified, and theirs is under /bin
#PING="/bin/ping -c1 -t1"
PING="/sbin/ping -c1 -t1"
# log file to use
LOGFILE="/var/log/you.lazy.motherfucker"
# time stamp to use
TIME=$(date +"%Y%m%d %H:%M:%S")
 
# functions to use, don't touch this shit below, it's fo' real.
# catch ctrl-c and break from the loop
trap ctrl_c INT
 
function ctrl_c() {
        break;
}
 
# do our ping tests.
DoPING () {
  F=0; IPSIZE="${#IP[@]}"
 
  # loop through all the IP's in our array and test them
  for (( I=0; I<"$IPSIZE"; I++ ))
  do
    # ping the IP, if packet received all is good.
    [[ $($PING ${IP[$I]}|grep received|awk '{ print $4 }') -eq 0 ]] && F=$(($F+1))
  done
 
  # if 3 failures detected, return false.
  [[ "$F" -eq "$IPSIZE" ]] && return 1 || return 0
}
 
# loop like a boss
DoLOOP () {
  while :
   do
    # do the ping test
    TEST=$(DoPING)
 
    # if all 3 failed, we need to record that shit.
    [[ "$TEST" -eq "1" ]] && X=$(($X+1))
 
    # well looks like we're having an outage, lets record more stuff
    [[ "$X" -eq "$LOGFAIL" ]] && echo "Failure start time: $TIME" >> "$LOGFILE"
 
    # looks like the outage is over, we'd better stop recording it as such (and reset $x)
    [[ "$X" -gt "$LOGFAIL" && "$TEST" -eq "0" ]] && { echo "Failure stop time: $TIME" >> "$LOGFILE"; X=0; }
 
    # sleep appropriate time and start again.
    sleep "$TESTINT"
  done
}
 
DoLOOP
# exit like a boss
exit 0
