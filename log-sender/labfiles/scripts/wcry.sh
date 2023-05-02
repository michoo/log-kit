#!/bin/sh
 
tcpreplay --loop=3 --topspeed -i eth1  /demo/qflows/wcry.pcap 2> /dev/null &
 
