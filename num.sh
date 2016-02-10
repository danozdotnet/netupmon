#!/bin/bash
#
# Network Uptime Monitor v0.5
# Copyright 2016 Danoz <danoz@danoz.net>
 
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
 
# functions to use, don't touch the shit below, it's fo' real.
# catch ctrl-c and break from the loop
trap ctrl_c INT
 
# break out of the while loop when we catch ctrl-c
function ctrl_c() {
  break;
}
 
# process options passed on the command line
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
 
  # if no option passed, run the loop
  [[ $OPTIND -eq 1 ]] && DoLOOP
  shift $((OPTIND-1))
}
 
# show help to noobs.
ShowHELP () {
  cat <<-ENDOFFILE
 
##########################################################################
# Network Uptime Monitor v0.5
# Copyright 2016 Danoz <danoz@danoz.net>
##########################################################################
 
Name:
ylm.sh [ -h | -r ]
     -h show this help.
     -r run a report totalling the information already collected
 
Purpose:
  This script is used to gather information about potential upstream
  internet connectivity issues. It will continuously ping a list of IP's
  and return the time an outage begins and finishes. Secondly, it will
  collate a report of any of all outages in a simple to read table.
 
Usage:
 
Example #1: "./num.sh"
 With no options, the script run in the ping test mode. It will ping the IP's
 you've specifed in the user variable section. It will run continuously.
 
Example #2: "./num.sh -r"
 With option -r, the script will run in report mode. In this mode it will
 tally the information collected in the previous mode and give a quantified
 output of any outages that were suffered.
 
 p.s.
 duk242 is one lazy motherfucker, so Danoz saved the day.
 
ENDOFFILE
}
 
# take input of seconds, convert to readable h:m:s
ConvertTIME () {
    h=$(( $1 / 3600 ))
    m=$(( $1 % 3600 / 60 ))
    s=$(( $1 % 60 ))
    printf "%02d:%02d:%02d\n" $h $m $s
}
 
# convert unix timestamp to readable date
ConvertDATE () {
  printf "$(date -d @$1 +"%d/%m/%Y %H:%M:%S")"
  # for freebsd:
  #printf "$(date -r $1 +"%d/%m/%Y %H:%M:%S")"
}
 
# record the time the failure started
StartFAIL () {
  StartTIME=$1
}
 
# record the time the failure finished, and work out the length
StopFAIL () {
  StopTIME=$1
 
  # calculate length of the outage
  OutageTIME="$((StopTIME-StartTIME))"
 
  # output start time and length of outage
  echo "$StartTIME:$OutageTIME" >> "$LOGFILE"
}
 
# print the header ;)
PrintHEADER () {
  cat <<-HEADER
====================================
Network Uptime Monitor - Failure Log
====================================
 
HEADER
}
 
# print the body of the outages
PrintBODY () {
  LOGARR=($(cat $LOGFILE))
  for row in "${LOGARR[@]}"
  do
    OLDIFS=$IFS
    IFS=":"
    cols=($row)
    IFS=$OLDIFS
    [[ "${cols[1]}" == "start" ]] \
      && printf "%s\tLog Start\n" "$(ConvertDATE "${cols[0]}")"
    [[ "${cols[1]}" =~ ^-?[0-9]+$ ]] \
      && printf "%s\t%s\n" "$(ConvertDATE "${cols[0]}")" "$(ConvertTIME "${cols[1]}")"
    [[ "${cols[1]}" == "end" ]] \
      && printf "%s\tLog End\n" "$(ConvertDATE "${cols[0]}")"
  done
}
 
# calculate all the info needed to summarise
CalculateSUMMARY () {
  NUMOUTAGES=$(grep -c -Ev 'start|end' $LOGFILE)
  OUTLENGTH="0"
  MAXLENGTH="0"
  MINLENGTH="0"
  for row in "${LOGARR[@]}"
  do
    IFS=":"
    cols=($row)
    # find start and end of logging
    [[ "${cols[1]}" == "start" ]] && STARTTIME="${cols[0]}"
    [[ "${cols[1]}" == "end" ]]  && ENDTIME="${cols[0]}"
    if [[ "${cols[1]}" =~ ^-?[0-9]+$ ]]; then
      # record incremental length of outages
      OUTLENGTH=$((OUTLENGTH+${cols[1]}))
      # set new max length if value is bigger
      [[ "${cols[1]}" -gt "$MAXLENGTH" ]] && MAXLENGTH="${cols[1]}"
      # set minlength if it's empty
      [[ "$MINLENGTH" -eq "0" ]] && MINLENGTH="${cols[1]}"
      # if new value is smaller, set new min value
      [[ "${cols[1]}" -lt "$MINLENGTH" ]] && MINLENGTH="${cols[1]}"
    fi
  done
 
  # calculate all the different times with the raw values from above
  LOGTIME=$((ENDTIME-STARTTIME))
  TOTALDOWNTIME=$(ConvertTIME $OUTLENGTH)
  PERCENTDOWN=$(awk -v t1="$OUTLENGTH" -v t2="$LOGTIME" 'BEGIN{ printf "%.2f", t1/t2 * 100 }')
  AVGLENGTH=$((OUTLENGTH / NUMOUTAGES))
}
 
# print the footer and summary
PrintFOOTER () {
  # calculate all the summary data and fill the variables.
  CalculateSUMMARY
  cat <<-FOOTER
 
Monitor Duration:       $(ConvertTIME $LOGTIME)
 
Failure Summary:
 
Number of Outages       $NUMOUTAGES
Total Downtime          $TOTALDOWNTIME
Precentage Down         $PERCENTDOWN%
Minimum Length          $(ConvertTIME $MAXLENGTH)
Maximum Length          $(ConvertTIME $MINLENGTH)
Average Length          $(ConvertTIME $AVGLENGTH)
 
====================================
FOOTER
}
 
 
# print a nicely tabulated summary of the outages
RunREPORT () {
  PrintHEADER
  PrintBODY
  PrintFOOTER
}
 
# do our ping tests.
DoPING () {
  F=0; IPSIZE="${#IP[@]}"
 
  # loop through all the IP's in our array and test them
  for (( I=0; I<"$IPSIZE"; I++ ))
  do
    # ping the IP, if packet received all is good.
    [[ $($PING ${IP[$I]}|grep received|awk '{ print $4 }') -eq 0 ]] && F=$((F+1))
  done
 
  # if 3 failures detected, return false.
  [[ "$F" -eq "$IPSIZE" ]] && echo 1 || echo 0
}
 
# loop like a boss
DoLOOP () {
  # echo start time to log
  echo "$(date +%s):start" >> "$LOGFILE"
  while :
   do
    # do the ping test
    TEST=$(DoPING)
 
    # if all 3 failed, we need to record that shit.
    [[ "$TEST" -eq "1" ]] && X=$((X+1))
 
    # well looks like we're having an outage, lets record more stuff
    [[ "$X" -eq "$LOGFAIL" ]] && StartFAIL "$(date +%s)"
 
    # looks like the outage is over, we'd better stop recording it as such (and reset $x)
    [[ "$X" -gt "$LOGFAIL" && "$TEST" -eq "0" ]] && { StopFAIL "$(date +%s)"; X=0; }
 
    # sleep appropriate time and start again.
    sleep "$TESTINT"
  done
  # on break, print end time.
  echo "$(date +%s):end" >> "$LOGFILE"
}
 
GetOPS "$@"
# exit like a boss
exit 0
