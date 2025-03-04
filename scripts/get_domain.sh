#!/bin/bash
whoami
date
hostname -f
dnsdomainname

ip_addr=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d:)

echo $ip_addr

hdomain=$(dnsdomainname)

echo $hdomain

new_hdns=$(nslookup $ip_addr | grep -E "\=\s.*" | cut -f2 -d=)

echo $new_hdns

if [ -z "$hdomain" ]; 
then echo "Domain entry is$new_hdns"; 
else echo "Domain entry is $hdomain"; 
fi

