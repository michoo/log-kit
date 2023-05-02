#!/bin/sh
 
#Type B superflow attacking the DNS server on the DMZ
tcpreplay -i eth1 -x 2.0 --loop=2 -T nano /demo/chrisdemo/typeB.pcap 2> /dev/null &
