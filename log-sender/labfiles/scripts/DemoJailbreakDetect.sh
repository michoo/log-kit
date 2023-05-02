#!/bin/sh

tcpreplay -i eth1  /demo/qflows/iTouch_pcap/cydia_app.pcap 2> /dev/null &

