#!/bin/bash

touch ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer1.conf

cd ~/autoSplunkDeployment

ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer1.conf

sed -i '/@management:/d' ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer1.conf

deploymentServer=$(cat ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer1.conf)

sleep 5 # Wait five seconds

touch ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer2.conf

cd ~/autoSplunkDeployment

ansible $deploymentServer -m gather_facts | grep -i ansible_fqdn | cut -f2 -d: > ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer2.conf

sed -i -e 's/^\s"//' -e 's/",$//' ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer2.conf

new_init_ds=$(cat ~/autoSplunkDeployment/scripts/mgmt_scripts/deploymentServer2.conf)

sleep 5 # Wait another five seconds

sed -i "s/splk-asdf/$new_init_ds/" ~/autoSplunkDeployment/splunkapps/z_deploymentclient/local/deploymentclient.conf

cd ~/autoSplunkDeployment/splunkapps/

rm z_deploymentclient.tgz

tar -zcvf z_deploymentclient.tgz z_deploymentclient/
