#!/bin/bash

shc_member=$(hostname -f)

/opt/splunk/bin/splunk init shcluster-config -auth admin:sysadmin01 -mgmt_uri https://$shc_member:8089 -replication_port 8181 -replication_factor 2 -conf_deploy_fetch_url https://splk-mgmt-00.us-east1-b.c.nasdaqhigh-456-451020.internal:8089 -secret shclustering01 -shcluster_label shcluster-lab

sleep 30

/opt/splunk/bin/splunk restart
