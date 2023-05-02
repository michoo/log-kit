#!/bin/bash

sudo /usr/bin/tcpreplay -i "eth1" -x 10.00 -T gtod --no-flow-stats --loop 20 --unique-ip /demo/qflows/onlytor.pcap 2>/demo/scripts/mylog.log &
#tcpreplay -i eth1 -x 10.00 -T nano /demo/qrif/materials/demo5.pcap 2>/demo/scripts/mylog.log &
