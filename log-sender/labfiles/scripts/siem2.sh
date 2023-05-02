#!/bin/sh
 
#Replay Port Scan to DMZ Web Server from Foreign Host
tcpreplay --loop=3 --topspeed -i eth1  /demo/chrisdemo/Portscan.pcap 2> /dev/null &
sleep 40
#Play SSH Authentication Fail followed by Success from Foreign Host
/opt/qradar/bin/logrun.pl -f /demo/chrisdemo/SSHD_Auth.txt -u 10.100.18.12 10 2> /dev/null &
 
