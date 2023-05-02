#!/bin/sh

/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_1_Postfix.syslog -u 10.64.2.30 2 2> /dev/null
sleep 5
/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_2_Bluecoat.syslog -u 192.168.10.224 1 2> /dev/null
sleep 5
/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_3_SEP.syslog -u 10.64.2.200 1 2> /dev/null
sleep 5
/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_4_Bluecoat.syslog -u 192.168.10.224 1 2> /dev/null
sleep 5
/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_5_SEP.syslog -u 10.64.2.200 1 2> /dev/null
sleep 5
/opt/qradar/bin/logrun.pl -f /demo/events/cozyduke/CozyDuke_6_Bluecoat.syslog -u 192.168.10.224 1 2> /dev/null
