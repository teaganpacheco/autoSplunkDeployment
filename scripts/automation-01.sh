#!/bin/bash

# Management Combo box standup after 18-21
# Step 18 
cd ~/ansible; ansible-playbook -K splunk/dev/base-mgmt.yml 

sleep 60
# Step 19
cd ~/ansible; scripts/mgmt_scripts/clusteringSetup.sh

sleep 10
# Step 20
touch ~/ansible/scripts/mgmt_scripts/mgmt_combo_ip.conf; cd ~/ansible; ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > ~/ansible/scripts/mgmt_scripts/mgmt_combo_ip.conf; sed -i '/@management:/d' ~/ansible/scripts/mgmt_scripts/mgmt_combo_ip.conf;

mgmt_combo_ip=$(cat ~/ansible/scripts/mgmt_scripts/mgmt_combo_ip.conf)

sleep 5
# Step 21
scp -i ~/.ssh/ansible ~/ansible/scripts/mgmt_scripts/mgmtSplkAppUpdate.sh splunk@$mgmt_combo_ip:/opt/splunk/etc/

sleep 10

cd ~/ansible; ansible $mgmt_combo_ip -m shell -a "/opt/splunk/etc/mgmtSplkAppUpdate.sh; /opt/splunk/bin/splunk restart"

# sleep 15 

# # Step 22

# cd ~/ansible; ansible-playbook -K gcp/dev/splk-idxcluster.yml 

# sleep 15
