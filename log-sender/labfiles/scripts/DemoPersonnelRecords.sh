#!/bin/sh

cd /demo/multitenancy/PersonnelRecords

/opt/qradar/bin/logrun.pl -f ./step1-winlogon.log -u 10.73.1.145 1 2> /dev/null &

/opt/qradar/bin/logrun.pl -f ./catch2.log -u 10.73.1.145 5 2> /dev/null &

wait 

/opt/qradar/bin/logrun.pl -f ./pers_fw_denies.log -u 10.69.1.1 10 2> /dev/null &

wait 

/opt/qradar/bin/logrun.pl -f ./pers-oracle.log -u 10.66.7.45 1 2> /dev/null &

wait

/opt/qradar/bin/logrun.pl -f ./catch6.log -u 10.73.1.145 10 2> /dev/null &

wait

