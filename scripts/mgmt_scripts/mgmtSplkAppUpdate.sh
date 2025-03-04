#!/bin/bash

new_mgmt=$(hostname -f)

sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/apps/mgmt_cmanager/local/server.conf
# sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/master-apps/idx_clustering/local/server.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/master-apps/all_license/local/server.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/apps/all_outputs/local/outputs.conf

# sed -i "s/splk-asdf/$new_mgmt/g" /opt/splunk/etc/shcluster/apps/sh_clustering/local/server.conf
# sed -i "s/splk-asdf/$new_mgmt/g" /opt/splunk/etc/shcluster/apps/sh_init_clustering/bin/shClusteringInitialization.sh
sed -i "s/splk-asdf/$new_mgmt/g" /opt/splunk/etc/shcluster/apps/sh_clustering/default/server.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/shcluster/apps/all_outputs/local/outputs.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/shcluster/apps/all_license/local/server.conf

sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/deployment-apps/z_deploymentclient/local/deploymentclient.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/deployment-apps/all_outputs/local/outputs.conf
sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/deployment-apps/all_license/local/server.conf

sed -i "s/splk-asdf/$new_mgmt/" /opt/splunk/etc/sh_init_clustering/bin/shClusteringInitialization.sh
