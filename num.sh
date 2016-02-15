#!/bin/bash
#
# Network Uptime Monitor v0.7.1
# Copyright 2016 Daniel Jones
# All Rights Reserved
# Released under the MIT License.

# User variables, change these to values that suit.

# change these to your preferred DNS Servers/or IP's of interest 
# to ping (add as many as you want!)
IP=( "8.8.8.8" "4.2.2.2" "208.67.222.222" )
# set test interval to every X seconds
TESTINT="1"
# mark as failure after X intervals in a row of outage
LOGFAIL="5"
# set ping timeout value (in milliseconds). if fping is not installed (on linux/bsd)
# then timeout cannot be smaller than 1 second (and will be set as such).
TIMEOUT="200"
# log file to store times of outages
LOGFILE="./netupmon.log"

# catch ctrl-c and break from the loop
trap ctrl_c INT

# break out of the while loop when we catch ctrl-c
function ctrl_c() {
  break;
}

# detect OS and set OS specific variables.
DetectOS () {
  # check for fping
  FPING=$(type fping2 >/dev/null 2>&1)
  [[ "$FPING" ]] || TIMEOUT="1"

  case "$OSTYPE" in
    msys*)
      OS="win32"; PING="ping -n 1 -w $TIMEOUT";;
    freebsd*)
      OS="bsd"; 
      [[ "$FPING" ]] && PING="fping -c 1 -t $TIMEOUT -u -q" || PING="ping -c1 -t1";; 
    linux*)
      OS="linux"; 
      # if linux system is a ubiquiti, path to ping required (and ttl helps)
      [[ $(uname -r | grep -c UBNT) -eq "1" ]] && PING="/bin/ping -c1 -t100 -W1" || PING="ping -c1 -W1";
      [[ "$FPING" ]] && PING="fping -c 1 -t $TIMEOUT -u -q";;
    *)
      echo "unknown OS, exiting."; exit 0;;
  esac
}

# process options passed on the command line
GetOPS () {
  # check OS first, then continue if good
  DetectOS

  while getopts ":rthz" opt; do
    case $opt in
      h)
        ShowHELP; exit 0;;
      r)
        PrintREPORT; exit 0;;
      t)
        DoLOOP; exit 0;;
      z)
        ResetLOG; DoLOOP; exit 0;;
      \?)
        echo "Invalid option: -$OPTARG" >&2 ;;
    esac
  done

  # if no option passed, show simple usage
  [[ $OPTIND -eq 1 ]] && ShowUSAGE
  shift $((OPTIND-1))
}

# simple usage when nothing specified
ShowUSAGE () {
  cat <<-USAGE
No flag specified, please use one of the below listed options.

num.sh [ -h | -t | -r | -z ]
     -h show the help screen
     -t run the ping test
     -r run a report totalling the information already collected
     -z reset the log file, then run the ping test.
USAGE
}

# show full help
ShowHELP () {
  cat <<-ENDOFFILE

###############################################################################
# Network Uptime Monitor v0.7.1                                               #
# Copyright 2016 Daniel Jones                                                 #
###############################################################################

Name:
num.sh [ -h | -t | -r | -z ]
     -h show the help screen
     -t run the ping test
     -r run a report totalling the information already collected
     -z reset the log file, then run the ping test.

Purpose:
 This script is used to gather information about potential upstream
 internet connectivity issues. It will continuously ping a list of IPs
 and return the time an outage begins and finishes. Secondly, it will
 collate a report of any of all outages in a simple to read table.

Usage:

Example #1: "./num.sh -t"
 With this option, the script run in the ping test mode. It will ping the IPs
 you have specifed in the user variable section. It will run continuously. If
 you CTRL+C out of the script, it will finish up cleanly and close out the
 outage log.

Example #2: "./num.sh -r"
 With option -r, the script will run in report mode. In this mode it will
 tally the information collected in the previous mode and give a quantified
 output of any outages that were suffered.

ENDOFFILE
}

# reset the log file.
ResetLOG () {
  rm "$LOGFILE"
  touch "$LOGFILE"
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
  [[ "$OS" == "linux" ]] && printf "%s" "$(date -d @"$1" +"%d/%m/%Y %H:%M:%S")"
  # for freebsd:
  [[ "$OS" == "bsd" ]] && printf "%s" "$(date -r "$1" +"%d/%m/%Y %H:%M:%S")"
}

# record the time the failure started
StartFAIL () {
  StartTIME=$1
}

# record the time the failure finished, and work out the length
StopFAIL () {
  StopTIME=$1

  # calculate length of the outage, then output to log
  OutageTIME="$((StopTIME-StartTIME))"
  echo "$StartTIME:$OutageTIME" >> "$LOGFILE"
}

# print the header, then extract/calculate all the info, then print body
# footer with all userful information
PrintREPORT () {
  # check if log file exists
  [[ -s "$LOGFILE" ]] || \
    { echo "Log file does not exist, either location is wrong or you haven't run in test mode yet."; exit 0; }
  # print the header
  cat <<-HEADER

=======================================
 Network Uptime Monitor - Failure Log
=======================================

HEADER
  # set some sane/useful values
  NUMOUTAGES=$(grep -c -Ev 'start|end' $LOGFILE)
  OUTLENGTH="0"
  MAXLENGTH="0"
  MINLENGTH="0"
  LOGARR=($(cat $LOGFILE))
  # set end time to be report runtime, unless it's already
  # recorded and gets overwritten later.
  ENDTIME="$(date +%s)"
  # iterate over the logfile
  for row in "${LOGARR[@]}"
  do
    # don't have 2 dimensional arrays in bash, hack around it.
    OLDIFS=$IFS
    IFS=":"
    cols=($row)
    IFS=$OLDIFS
    # check for start/stop of monitoring, otherwise calculate outage times
    [[ "${cols[1]}" == "start" ]] \
      && printf " %s\t   Log Start\n" "$(ConvertDATE "${cols[0]}")"
    [[ "${cols[1]}" =~ ^-?[0-9]+$ ]] \
      && printf " %s\t   %s\n" "$(ConvertDATE "${cols[0]}")" "$(ConvertTIME "${cols[1]}")"
    [[ "${cols[1]}" == "end" ]] \
      && printf " %s\t   Log End\n" "$(ConvertDATE "${cols[0]}")"

    # extract info for summary.
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
  [[ "$NUMOUTAGES" == "0" ]] && AVGLENGTH="0" || AVGLENGTH=$((OUTLENGTH / NUMOUTAGES))

  cat <<-SUMMARY

 Monitor Duration:         $(ConvertTIME $LOGTIME)

 Failure Summary:

 Number of Outages         $NUMOUTAGES
 Total Downtime            $TOTALDOWNTIME
 Precentage Down           $PERCENTDOWN%
 Minimum Length            $(ConvertTIME "$MINLENGTH")
 Maximum Length            $(ConvertTIME "$MAXLENGTH")
 Average Length            $(ConvertTIME "$AVGLENGTH")

=======================================

SUMMARY
}

# do our ping tests.
DoPING () {
  F=0; IPSIZE="${#IP[@]}"

  # loop through all the IP's in our array and test them
  for (( I=0; I<"$IPSIZE"; I++ ))
  do
    [[ "$FPING" ]] && \
    # fping specific check:
    [[ $($PING "${IP[$I]}" 2>&1 | grep -c Unreachable) -eq 1 ]] && F=$((F+1)) || \
    # ping the IP, if packet received all is good.
    [[ $($PING "${IP[$I]}" |grep -i received|awk '{ print substr($4,1,1) }') -eq 0 ]] && F=$((F+1))
  done

  # if 3 failures detected, return false.
  [[ "$F" -eq "$IPSIZE" ]] && echo 1 || echo 0
}

# loop like a boss
DoLOOP () {
  # echo start time to log if log file is empty (or doesn't exist)
  [[ -s "$LOGFILE" ]] || echo "$(date +%s):start" >> "$LOGFILE"
  while :
   do
    # do the ping test
    TEST=$(DoPING)

    # if all 3 failed, we need to record that shit.
    [[ "$TEST" -eq "1" ]] && X=$((X+1))

    # when failures stop, reset X
    [[ "$TEST" -eq "0" ]] && X="0"

    # once we have a failure, remember the time it started so we can use that later.
    [[ "$X" -eq "1" ]] && STARTFAIL=$(date +%s)

    # reset STARTFAIL, so we don't use that date for a later failure
    [[ "$X" -eq "0" ]] && STARTFAIL=""

    # well looks like we're having an outage, lets record more stuff
    [[ "$X" -eq "$LOGFAIL" ]] && StartFAIL "$STARTFAIL"

    # looks like the outage is over, we'd better stop recording it as such (and reset $x)
    [[ "$X" -ge "$LOGFAIL" && "$TEST" -eq "0" ]] && StopFAIL "$(date +%s)"

    # sleep appropriate time and start again.
    sleep "$TESTINT"
  done
  # on break, print end time.
  echo "$(date +%s):end" >> "$LOGFILE"
}

GetOPS "$@"
# exit like a boss
exit 0