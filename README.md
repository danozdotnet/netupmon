# Network Uptime Monitor v0.6
## Copyright 2016 Danoz <danoz@danoz.net>


###Name:
####num.sh [ -h | -r ]
     -h show this help.
     -r run a report totalling the information already collected

###Purpose:
  This script is used to gather information about potential upstream
  internet connectivity issues. It will continuously ping a list of IPs
  and return the time an outage begins and finishes. Secondly, it will
  collate a report of any of all outages in a simple to read table.

###Usage:

####Example #1: "./num.sh"
 With no options, the script run in the ping test mode. It will ping the IPs
 you have specifed in the user variable section. It will run continuously.

####Example #2: "./num.sh -r"
 With option -r, the script will run in report mode. In this mode it will
 tally the information collected in the previous mode and give a quantified
 output of any outages that were suffered.
