
import time
import os

firewallAllowLogSample = "<166>%ASA-6-302013: Built inbound TCP connection 103248504 for outside:159.253.42.171/2381 (159.253.42.171/2381) to DMZ:192.168.4.19/80 (192.168.4.19/80)\n"


#List1 = [112,118,132,129,121,135,148,148,136]
List1 = [120,112,99,109,115,101,110,300,103,108,100,109,100,138,112,97,110,120]

for i in List1:
	starttime=time.time()
	target = open("log.log", 'w')
	target.write(firewallAllowLogSample * i)
	target.close()
	os.system("/opt/qradar/bin/logrun.pl -u myFirewall -f log.log 500")
	time.sleep(60.0 - ((time.time() - starttime) % 60.0))
