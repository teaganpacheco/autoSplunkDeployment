#!/bin/bash

new_mgmt=$(hostname -f)

# sudo awk '{sub(/splk-mgmt-00/,"$new_mgmt"); print . "/opt/splunk/etc/apps/mgmt_cmanager/local/server.conf" }' > /opt/splunk/etc/apps/mgmt_cmanager/local/server.conf

# sudo awk '{sub(/splk-mgmt-00/,"splk-mgmt-00.us-east1-b.c.starry-knight-98765.internal"); print . "/opt/splunk/etc/apps/mgmt_cmanager/local/server.conf" }' > /opt/splunk/etc/apps/cmanager/local/server.conf

# sed -i "s/splk-mgmt-00/splk-mgmt-00.us-east1-b.c.starry-knight-98765.internal/" /opt/splunk/etc/apps/mgmt_cmanager/local/server.conf


sed -i "s/splk-mgmt-00/$new_mgmt/" /opt/splunk/etc/apps/mgmt_cmanager/local/server.conf

sed -i "s/splk-mgmt-00/$new_mgmt/" /opt/splunk/etc/deployment-apps/all_license/local/server.conf

sed -i "s/splk-mgmt-00/$new_mgmt/" /opt/splunk/etc/deployment-apps/idxclustering/local/server.conf

sed -i "s/splk-mgmt-00/$new_mgmt/g" /opt/splunk/etc/deployment-apps/shclustering/local/server.conf

# sed -i "s/splk-mgmt-00/splk-mgmt-00.us-east1-b.c.starry-knight-98765.internal/g" /opt/splunk/etc/deployment-apps/shclustering/local/server.conf

# ansible 10.142.0.8 -m gather_facts | grep -i ansible_fqdn

# ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management

# ansible 10.142.0.8 -m gather_facts | grep -i ansible_fqdn | cut -f2 -d:
 "splk-mgmt-00.us-east1-b.c.starry-knight-98765.internal",

# ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f2 -d:

# ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '|'

# ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-'

# touch test.conf; ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > test.conf 

# awk '{sub(/@management:/,/); print}' test.conf
# sed -i "s/@management://g" test.conf

# sed -i '/@management:/d' test.conf
_______________________________________________________________

new_gcp_mgmt=$(touch test.conf; ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > test.conf; sed -i '/@management:/d' test.conf; cat test.conf)

new_ds=$(touch testds.conf; ansible $new_gcp_mgmt -m gather_facts | grep -i ansible_fqdn | cut -f2 -d: > testds.conf; sed -i -e 's/^\s"//' -e 's/",$//' testds.conf)

sed -i "s/splk-mgmt-00/$new_ds/" /home/teaganbhd/ansible/splunkapps/z_deploymentclient/local/deploymentclient.conf

sed -i "s/splk-mgmt-00/splk-mgmt-00.us-east1-b.c.starry-knight-98765.internal/" /home/teaganbhd/ansible/splunkapps/z_deploymentclient/local/deploymentclient.conf
