#!/usr/bin/python
# -*- encoding: iso-8859-1 -*-

from scapy.all import *
from random import randrange

ip = IP(src="172.21.0.3",dst="127.0.0.1")
udp = UDP(sport=50000,dport=5000)
data = '\x01\x0f'
pkt = ip/udp/data

packet = IP(raw(pkt))  # Build packet (automatically done when sending)
checksum_scapy = packet[UDP].chksum

print(checksum_scapy)



send(packet, verbose=0)
packet.show()