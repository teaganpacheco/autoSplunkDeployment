#!/bin/bash

touch ~/autoSplunkDeployment/inventory/tmpHosts.list

cd ~/autoSplunkDeployment

ansible sh_cluster_members -m shell -a "hostname -f" | grep -v CHANGED > ~/autoSplunkDeployment/inventory/tmpHosts.list

cd ~/autoSplunkDeployment/

rm ~/autoSplunkDeployment/inventory/new-tmpHosts.list

touch ~/autoSplunkDeployment/inventory/new-tmpHosts.list

sed -i 's/ //g' ~/autoSplunkDeployment/inventory/tmpHosts.list

sed -i 's/$/:8089/' ~/autoSplunkDeployment/inventory/tmpHosts.list

sed -i 's/^/https:\/\//' ~/autoSplunkDeployment/inventory/tmpHosts.list

tr '\n' , < ~/autoSplunkDeployment/inventory/tmpHosts.list > ~/autoSplunkDeployment/inventory/new-tmpHosts.list

sed -i 's/,$//' ~/autoSplunkDeployment/inventory/new-tmpHosts.list
