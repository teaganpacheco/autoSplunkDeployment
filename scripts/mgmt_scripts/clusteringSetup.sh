#!/bin/bash

touch ~/ansible/scripts/mgmt_scripts/test.conf

cd ~/ansible

ansible-inventory -i inventory/mygcp.gcp.yml --graph | grep -i -A 1 management | cut -f3 -d '-' > ~/ansible/scripts/mgmt_scripts/test.conf

sed -i '/@management:/d' ~/ansible/scripts/mgmt_scripts/test.conf

new_mgmt_host=$(cat ~/ansible/scripts/mgmt_scripts/test.conf)

idx_cluster_manager=$(cd ~/ansible; ansible $new_mgmt_host -m shell -a "hostname -f" | grep -v CHANGED) 

sed -i "s/splk-asdf/$idx_cluster_manager/g" ~/ansible/splunkapps/idx_clustering/local/server.conf

sed -i "s/splk-asdf/$idx_cluster_manager/g" ~/ansible/splunkapps/sh_clustering/default/server.conf

cd ~/ansible/splunkapps/

rm idx_clustering.tgz

tar -zcvf idx_clustering.tgz idx_clustering/

cd ~/ansible/splunkapps/

rm sh_clustering.tgz

tar -zcvf sh_clustering.tgz sh_clustering/
