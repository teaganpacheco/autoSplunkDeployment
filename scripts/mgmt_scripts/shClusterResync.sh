#!/bin/bash

sh_captain_hostname=$(cd ~/autoSplunkDeployment; ansible sh_cluster_members[0] -m shell -a "/opt/splunk/bin/splunk show shcluster-status -auth admin:sysadmin01" | grep -i Captain\: -A 6 | grep -i mgmt_uri | awk '{$1=$1;print}' | cut -c20-73)

sh_captain_ip=$(ping -c 1 $sh_captain_hostname | grep "64 bytes from " | awk '{print $5}' | cut -d":" -f1 | tr -d '()')

cd ~/autoSplunkDeployment; ansible $sh_captain_ip -m shell -a "/opt/splunk/bin/splunk stop; tar -zcvf /tmp/shCaptainBundles.tgz /opt/splunk/var/run/; rm -f -r /opt/splunk/var/run/*; /opt/splunk/bin/splunk start; /opt/splunk/bin/splunk resync shcluster-replicated-config -auth admin:sysadmin01"
