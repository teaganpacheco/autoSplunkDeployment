#!/bin/bash

#new connectivity test

#variables with items to test
dns_list=('splunk-umbrella.cyber.ray.com' 'depotds.rockwellcollins.com' 'splunk.utc.com' 'search.splunk.cert.ray.com')

connect_list=('splunk-umbrella.cyber.ray.com:8089' '10.50.10.95:8089' 'splunk.cyber.ray.com:443' 'depotds.rockwellcollins.com:8089' '10.165.78.32:9997' '10.180.12.53:9997' '138.126.126.50:9997' '10.50.10.199:9997' '10.50.10.202:9997' '10.50.10.203:9997' '10.50.10.204:9997')

#get system details
endpoint=$(hostname -f)
#get/add other details? (domain, IP, etc)

#get splunk home
echo "hostname=$endpoint test=splunk_data value=splunk_home result=$SPLUNK_HOME"
sleep 2

#get deployclient file
deploy_client_file=$($SPLUNK_HOME/bin/splunk btool --debug deploymentclient list | grep targetUri | sed s/\\s.*$//g)
echo "hostname=$endpoint test=splunk_data value=deploy_client_conf_file result=$deploy_client_file"
sleep 2

fail_dns_count=0
total_dns_count=${#dns_list[@]}

#test each DNS entry
for i in "${dns_list[@]}"
do
        dns_test=$(nslookup $i | grep "Address:" | grep -v "#" | sed 's/Address:\s*//g')
        if [ -z "$dns_test" ]
        then
                dns_test="UNRESOLVED"
                fail_dns_count=$((fail_dns_count+1))
        fi
        echo "hostname=$endpoint test=dns_check value=$i result=$dns_test"
        sleep 2
done

#print DNS summary
success_dns_count=$((total_dns_count-fail_dns_count))
echo "hostname=$endpoint test=dns_summary value=$total_dns_count result=$success_dns_count"
sleep 2

success_connect_count=0
total_connect_count=${#connect_list[@]}

#test each network entry

for i in "${connect_list[@]}"
do
        ip=${i%%:*}
        port=${i##*:}
        connect_test=$(timeout 5 echo > /dev/tcp/$ip/$port > /dev/null 2>&1 && echo "SUCCESS" || echo "FAIL")
        echo "hostname=$endpoint test=connectivity_check value=$i result=$connect_test"
        sleep 2
        if [ "$connect_test" = "SUCCESS" ]
        then
                success_connect_count=$((success_connect_count+1))
        fi
done

#print Connectivity summary
echo "hostname=$endpoint test=connectivity_summary value=$total_connect_count result=$success_connect_count"
