#!/bin/sh
 
/opt/qradar/bin/logrun.pl -f /demo/events/PetyaProcessLogs.log 1  2> /dev/null &

sleep 20s


/opt/qradar/bin/logrun.pl -f /demo/events/PetyaProcessLogs2.log 1  2> /dev/null & 

