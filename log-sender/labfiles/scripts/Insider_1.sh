#!/bin/sh

 

#Play User Login Followed by USB Device Action Followed By Web Upload
echo "playing Auth.txt logs"
/opt/qradar/bin/logrun.pl -f /demo/events/Auth.txt -u WIN7 1 2> /dev/null &

sleep 9

echo "playing USB_insert.txt logs"
/opt/qradar/bin/logrun.pl -f /demo/events/USB_insert.txt -u 10.64.2.210 5 2> /dev/null &

sleep 5

echo "playing Insider1_proxy.txt logs"
/opt/qradar/bin/logrun.pl -f /demo/events/Insider1_Proxy.txt -u 192.168.10.224 5 2> /dev/null &

sleep 6

echo "playing USB_remove.txt logs"
/opt/qradar/bin/logrun.pl -f /demo/events/USB_remove.txt -u 10.64.2.210 5 2>/dev/null &

sleep 6

echo "playing Logoff.txt logs"
/opt/qradar/bin/logrun.pl -f /demo/events/Logoff.txt -u WIN7 1 2>/dev/null &
