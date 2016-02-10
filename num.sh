#!/bin/bash
 
#
# Network Uptime Monitor v0.1
# Copyright 2016 Danoz <danoz@danoz.net>
#
 
# functions to use, leave this alone.
# catch ctrl-c and break from the loop
trap ctrl_c INT
 
function ctrl_c() {
        break;
}
 
# User variables
# you can change these to values that suit.
 
# change these to your preferred DNS
DNS1="8.8.8.8"
DNS2="4.2.2.2"
DNS3="208.67.222.222"
# test ever X seconds
TESTINT="1"
# mark as failure after X seconds of outage
LOGFAIL="5"
# adjust as necessary for your environment.
# ubiquiti routers need the path specified, and theirs is under /bin
PING="/bin/ping -c1"
#PING="/sbin/ping -c1"
# log file to use
LOGFILE="/var/log/you.lazy.motherfucker"
# time stamp to use
TIME=$(date +"%Y%m%d %H:%M:%S")
 
# don't touch this shit below, it's fo' real.
i=0; x=0
# loop forever like a boss.
while :
 do
  #test all 3 DNS addresses, if no packets recieved mark as failure.
  [[ $($PING $DNS1|grep received|awk '{ print $4 }') -eq 0 ]] && i=$(($i+1))
  [[ $($PING $DNS2|grep received|awk '{ print $4 }') -eq 0 ]] && i=$(($i+1))
  [[ $($PING $DNS3|grep received|awk '{ print $4 }') -eq 0 ]] && i=$(($i+1))
 
  # if all 3 failed, we need to record that shit.
  [[ "$i" -eq "3" ]] && x=$(($x+1))
 
  # well looks like we're having an outage, lets record more stuff
  [[ "$x" -eq "5" && "$i" -eq "3" ]] && echo "Failure start time $TIME" >> "$LOGFILE"
 
  # looks like the outage is over, we'd better stop recording it as such
  [[ "$x" -gt "5" && "$i" -ne "3" ]] && { echo "Failure stop time $TIME" >> "$LOGFILE"; x=0; }
 
  # sleep appropriate time and start again.
  sleep "$TESTINT"
 
  # reset i before we loop
  i=0
done
 
# exit like a boss
exit 0
