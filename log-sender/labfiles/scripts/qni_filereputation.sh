#!/bin/bash
#This script throws a huge 2 GB pcap into QNI.
#it is suggested that tech sellers use this one to show QNI in real time.
#In the Network Tab, use the quick search called, "QNI_File_Hash_RT."

#This gives you a few minutes to describe QNI.

#A few minutes later, show the Incident Overview with tons of offenses.
#In particular, see the offense with the Description, 
#"X-Force Internal Connection to Possible Malware Host
#preceded by Observed File Hash Seen Across Multiple Hosts
#preceded by Observed File Hash Associated with Malware Threat
#preceded by Internal Connection to Possible Malware Host
#containing Web.HTTPWeb."

#Uploading 2GB from the console VM into qni takes about 15 min.
#So, move in from local qni vm, which takes under 1 min.
sudo scp root@qni:/demo/qni_cache2/final_merged.pcap root@qni:/opt/ibm/forensics/case_input/democase/singles/.
