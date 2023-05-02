#!/bin/sh
/opt/qradar/bin/logrun.pl -u 192.168.5.95 -f /demo/events/cilasoft/LEEF_ALL_OPS.txt -l -v 1
/opt/qradar/bin/logrun.pl -u 192.168.1.17 -f /demo/events/cilasoft/CiscoFWSM_SecEvents.txt -l -v 1
/opt/qradar/bin/logrun.pl -u 192.168.5.201 -f /demo/events/cilasoft/LINUX_LOGS.txt  -l -v 1
