#!/bin/sh

/opt/qradar/bin/logrun.pl -f /demo/badgenvpn/badge.log -u 10.1.230.112 10 2> /dev/null &

/opt/qradar/bin/logrun.pl -f /demo/badgenvpn/vpn.log -u 10.1.230.2 10 2> /dev/null &

