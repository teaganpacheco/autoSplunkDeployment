#!/bin/bash

shc_member=$(hostname -f)

/opt/splunk/bin/splunk init shcluster-config -auth admin:sysadmin01 -mgmt_uri https://$shc_member:8089 -replication_port 8181 -replication_factor 2 -conf_deploy_fetch_url https://splk-asdf:8089 -secret shclustering01 -shcluster_label shcluster-lab

cd /opt/splunk/etc/apps/sh_init_clustering/local; mv inputs.conf inputs.conf.old
