#!/bin/bash

touch ~/ansible/inventory/tmpHosts.list

cd ~/ansible

ansible sh_cluster_members -m shell -a "hostname -f" | grep -v CHANGED > ~/ansible/inventory/tmpHosts.list

cd ~/ansible/

rm ~/ansible/inventory/new-tmpHosts.list

touch ~/ansible/inventory/new-tmpHosts.list

sed -i 's/ //g' ~/ansible/inventory/tmpHosts.list

sed -i 's/$/:8089/' ~/ansible/inventory/tmpHosts.list

sed -i 's/^/https:\/\//' ~/ansible/inventory/tmpHosts.list

tr '\n' , < ~/ansible/inventory/tmpHosts.list > ~/ansible/inventory/new-tmpHosts.list

sed -i 's/,$//' ~/ansible/inventory/new-tmpHosts.list
