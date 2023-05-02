#tcpreplay -i eth0 -T nano /labfiles/attack/ms08_067_netapi_vuln_server_attack.pcap &
./logrun.pl -d 9.128.11.110 -u 192.168.10.11 -f attack/ms08_067_netapi_vuln_server_attack.snort.log 35
