#!/bin/sh
/opt/qradar/bin/logrun.pl -f /demo/multitenancy/SRX/leveraged_srx.syslog -u 10.69.1.2 -l 2 2> /dev/null &
/opt/qradar/bin/logrun.pl -f /demo/data/McAfee.syslog -u 10.64.2.10 -l 10 2> /dev/null &
/opt/qradar/bin/logrun.pl -f /demo/multitenancy/PersonnelRecords/step1-winlogon.log -u 10.64.2.11 -l 1 2> /dev/null & 
/opt/qradar/bin/logrun.pl -f /demo/multitenancy/PersonnelRecords/catch6.log -u 10.64.2.12 -l 10 2> /dev/null &
/opt/qradar/bin/logrun.pl -f /demo/multitenancy/nation-state/ssh.log -u 10.64.2.13 -l 10 2> /dev/null &
/opt/qradar/bin/logrun.pl -f /demo/data/Bluecoat_ProxySG_Jan2016.syslog -u 10.64.2.14 -l 10 2> /dev/null &
#/opt/qradar/bin/logrun.pl -f /demo/data/Microsoft_iis_w3c.log -u 10.64.2.15 -l 10 2> /dev/null &
