#!/usr/bin/python
# -*- encoding: iso-8859-1 -*-

import socket
import argparse
from scapy.all import *
from random import randrange



"""
syslogger [-d <host>] [-p <port>] [-f filename] [-u <IP>] [-l] [-t] [-b] [-n NAME] [-v] <messages per second>
Options:
-d : destination syslog host (default 127.0.0.1)
-p : destination port (default 514)
-f : filename to read (default readme.syslog)
-b : burst the same message for 20% of the delay time
-t : use TCP instead of UDP for sending syslogs
-v : verbose, display lines read in from file
///-n : use NAME for object name in syslog header
-l : loop indefinately
-u : use this IP as spoofed sender (default is NOT to send IP header)
"""

parser = argparse.ArgumentParser()
parser.add_argument('-d', "--dest", help="remote syslog server ip.", default="localhost")
parser.add_argument('-p', "--port", help="remove syslog server port.", type=int, default=5000)
parser.add_argument('-f', "--file", help="filename to read (default readme.syslog)", default="readme.syslog")
parser.add_argument('-b', "--burst", help="burst the same message for 20 percents of the delay time", type=int, default=1)
parser.add_argument('-t', "--tcp", help="use TCP instead of UDP for sending syslogs", default=False, action='store_true')
parser.add_argument('-v', "--verbose", help="verbose, display lines read in from file", default=False, action='store_true')
parser.add_argument('-l', "--loop", help="loop indefinately", default=False, action='store_true')
parser.add_argument('-u', "--spoofedip", help="use this IP as spoofed sender (default is NOT to send IP header)", default="localhost")
args = parser.parse_args()

def syslogScapy(filename, spoofed_ip='127.0.0.1', dest='127.0.0.1', port=5000):
    """
    Send syslog UDP packet to given dest and port.
    """
    with open(filename) as lines:

        # go over each line 
        for line in lines:

            # if line is not empty
            if line:
                send(IP(src=spoofed_ip,dst=dest)/UDP(sport=randrange(80,65535),dport=port)/line,iface="wlp3s0",count=1)
                if args.verbose:
                    print(line)

def syslogSocket(filename, spoofed_ip='127.0.0.1', dest='127.0.0.1', port=5000):

    with open(filename) as lines:

        # go over each line 
        for line in lines:

            # if line is not empty
            if line:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.sendto(line.encode(), (dest, port))
                sock.close()
                if args.verbose:
                    print(line)
                

#syslogScapy(filename=args.file, spoofed_ip=args.spoofedip,dest=args.dest,port=args.port)
syslogSocket(filename=args.file)