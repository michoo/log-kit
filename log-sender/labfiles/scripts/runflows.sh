#!/bin/bash

countflows=0
while [ $countflows -lt 90 ]; do

#        /usr/bin/tcpreplay -i eth1 -x 20.00 -T nano /demo/chained/DataSourcePlay
#er-122-data-skype2.pcap

sudo /usr/bin/tcpreplay -i eth1 -x 2.00 -T gtod --no-flow-stats --loop 60 --unique-ip /demo/qrif/materials/demo5.pcap 2>/demo/scripts/mylog.log &
sudo /usr/bin/tcpreplay -i eth1 -x 10.00 -T gtod --no-flow-stats --loop 60 --unique-ip /demo/qflows/onlytor.pcap 2> /dev/null &
sudo /usr/bin/tcpreplay -i eth1 -x 2.00 -T gtod --no-flow-stats --loop 60 /demo/qflows/iTouch_pcap/cydia_app.pcap 2> /dev/null &
sleep 10m

        countflows=`expr $countflows + 1`;
done

