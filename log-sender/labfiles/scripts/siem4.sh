#!/bin/sh
 
#Replay IRC traffic from local to remote Botnet C&C
tcpreplay -i eth1 -x 2.0 --loop=3 -T nano /demo/chrisdemo/irc.pcap 2> /dev/null &
