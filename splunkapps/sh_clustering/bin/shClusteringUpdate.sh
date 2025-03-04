#!/bin/bash

new_sh=$(hostname -f)

sed -i "s/splk-replace/$new_sh/" /opt/splunk/etc/apps/shclustering/local/server.conf
