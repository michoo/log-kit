#!/bin/bash
#Play in this file.  Then in the network tab there are about 10 saved searches
#With colorful QNI data.  There are no offenses from this.

#Upload from console into qni takes about 15 min.
#So, move in from local qni vm, which takes under 1 min.
sudo scp qni:/demo/qni_cache2/qni_orig_email_users/*.pcap qni:/opt/ibm/forensics/case_input/democase/singles/.
