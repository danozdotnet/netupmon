#!/bin/bash
 
#
# Network Uptime Monitor v0.3
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
# ubiquiti routers need the path specified:
#PING="/bin/ping -c1 -t100 -w1"
# FreeBSD style:
#PING="/sbin/ping -c1 -t1"
# Linux style:
PING="/bin/ping -c1 -W1"
# log file to use
LOGFILE="/var/log/netupmon.log"
# time stamp to use
TIME=$(date +"%Y%m%d %H:%M:%S")
 
# functions to use, don't touch the shit below, it's fo' real.
# catch ctrl-c and break from the loop
trap ctrl_c INT
 
# break out of the while loop when we catch ctrl-c
function ctrl_c() {
  break;
}
 
GetOPS () {
  while getopts ":rh" opt; do
    case $opt in
      h)
        ShowHELP; exit 0;;
      r)
        RunREPORT; exit 0;;
      \?)
        echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done
 
  [[ $OPTIND -eq 1 ]] && DoLOOP
  shift $((OPTIND-1))
}
 
ShowHELP () {
  cat <<-ENDOFFILE
##########################################################################
# Network Uptime Monitor v0.3
# Copyright 2016 Danoz <danoz@danoz.net>
##########################################################################
 
Name:
ylm.sh [ -h | -r ]
     -h show this help.
     -r run a report totalling the information already collected
 
Purpose:
 This script is used to gather information about potential upstream internet 
 connectivity issues. It will continuously ping a list of IPs and return the 
 time an outage begins and finishes. Secondly, it will collate a report of any 
 of all outages in a simple to read table.
 
Usage:
 
Example #1: "./num.sh"
 With no options, the script run in the ping test mode. It will ping the IP's
 you've specifed in the user variable section. It will run continuously.
 
Example #2: "./num.sh -r"
 With option -r, the script will run in report mode. In this mode it will
 tally the information collected in the previous mode and give a quantified
 output of any outages that were suffered.
ENDOFFILE
}
 
RunREPORT () {
  # TODO
  # look at the log file, make pretty tables and shit.
  return 0
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
  [[ "$F" -eq "$IPSIZE" ]] && echo 1 || echo 0
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
 
GetOPS "$@"
# exit like a boss
exit 0
