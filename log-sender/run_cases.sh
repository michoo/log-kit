#!/bin/bash

while true; do
#	./startAttack.sh;
#	./startFalse.sh;
#	./startFred.sh;
	for i in {1..20}; do
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.10.111 --filename labfiles/events/false/nips.syslog 30
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.10.112 --filename labfiles/events/false/ossec.syslog 30
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.2 --filename labfiles/events/PaloAltoNetworks/PASeries/PaloAlto_PASeries_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.10.254 --filename labfiles/events/report/rep1_prepared.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.10.254 --filename labfiles/events/report/rep2_prepared.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.3 --filename labfiles/events/Oracle/OSAudit/Oracle_OSAudit_33557.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.4 --filename labfiles/events/Microsoft/Windows/Microsoft_Windows_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.6 --filename labfiles/events/Microsoft/SQL/Microsoft_SQL_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.7 --filename labfiles/events/McAfee/IntruShield/McAfee_IntruShield_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.8 --filename labfiles/events/Juniper/NetscreenFW/Juniper_NetScreenFW_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.10 --filename labfiles/events/ISC/Bind/ISC_Bind_12189_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.11 --filename labfiles/events/Infoblox/NIOS/Infoblox_NIOS_20601.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.12 --filename labfiles/events/IBM/AS400/IBM_AS400_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.13 --filename labfiles/events/IBM/AIX/IBM_AIX_00000.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.14 --filename labfiles/events/GNU/LinuxServer/GNU_LinuxServer_15946.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.16 --filename labfiles/events/FireEye/MPS/FireEye_MPS_26482_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.17 --filename labfiles/events/F5Networks/FirePass/F5Networks_FirePass_17125.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.18 --filename labfiles/events/F5Networks/BigIP/F5Networks_BigIP_13332.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.19 --filename labfiles/events/Cisco/WiSM/Cisco_WiSM_24922.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.20 --filename labfiles/events/Cisco/VPNConcentrator/Cisco_VPN_00000_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.22 --filename labfiles/events/Cisco/Firewall/Cisco_ASA_17050_01.syslog 35
                ./logrunpy/logrun.py --dest 127.0.0.1 --port 5000 --sourceip 192.168.13.23 --filename labfiles/events/Cisco/ACS/Cisco_ACS_10742.syslog 35
		sleep 300s;
	done
	sleep 1200s;
done
