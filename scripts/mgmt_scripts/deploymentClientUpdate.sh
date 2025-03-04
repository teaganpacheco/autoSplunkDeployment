#!/bin/bash

touch ~/ansible/scripts/mgmt_scripts/deploymentServer1.conf

cd ~/ansible

ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > ~/ansible/scripts/mgmt_scripts/deploymentServer1.conf

sed -i '/@management:/d' ~/ansible/scripts/mgmt_scripts/deploymentServer1.conf

deploymentServer=$(cat ~/ansible/scripts/mgmt_scripts/deploymentServer1.conf)

sleep 5 # Wait five seconds

touch ~/ansible/scripts/mgmt_scripts/deploymentServer2.conf

cd ~/ansible

ansible $deploymentServer -m gather_facts | grep -i ansible_fqdn | cut -f2 -d: > ~/ansible/scripts/mgmt_scripts/deploymentServer2.conf

sed -i -e 's/^\s"//' -e 's/",$//' ~/ansible/scripts/mgmt_scripts/deploymentServer2.conf

new_init_ds=$(cat ~/ansible/scripts/mgmt_scripts/deploymentServer2.conf)

sleep 5 # Wait another five seconds

sed -i "s/splk-asdf/$new_init_ds/" ~/ansible/splunkapps/z_deploymentclient/local/deploymentclient.conf

cd ~/ansible/splunkapps/

rm z_deploymentclient.tgz

tar -zcvf z_deploymentclient.tgz z_deploymentclient/
