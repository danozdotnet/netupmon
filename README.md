# Network Uptime Monitor v0.7.1
## Copyright 2016 Daniel Jones, All Rights Reserved.
## Released under the MIT License.


###Name:
####num.sh [ -h | -t | -r | -z ]
	-h show the help screen
	-t run the ping test
	-r run a report totalling the information already collected
	-z reset the log file, then run the ping test.

###Purpose:

 This script is used to gather information about potential upstream
 internet connectivity issues. It will continuously ping a list of IPs
 and return the time an outage begins and finishes. Secondly, it will
 collate a report of any of all outages in a simple to read table.

###Usage:

####Example #1: "./num.sh -t"

 With this option, the script run in the ping test mode. It will ping the IPs
 you have specifed in the user variable section. It will run continuously. If
 you CTRL+C out of the script, it will finish up cleanly and close out the
 outage log.

####Example #2: "./num.sh -r"

 With option -r, the script will run in report mode. In this mode it will
 tally the information collected in the previous mode and give a quantified
 output of any outages that were suffered.
