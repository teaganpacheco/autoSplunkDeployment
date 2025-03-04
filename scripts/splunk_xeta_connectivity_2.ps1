#new connectivity test

#variables with items to test
$dns_list = @('splunk-umbrella.cyber.ray.com','depotds.rockwellcollins.com','splunk.utc.com','search.splunk.cert.ray.com')

$connect_list = @('splunk-umbrella.cyber.ray.com:8089','10.50.10.95:8089','splunk.cyber.ray.com:443','depotds.rockwellcollins.com:8089','10.165.78.32:9997','10.180.12.53:9997','138.126.126.50:9997','10.50.10.199:9997','10.50.10.202:9997','10.50.10.203:9997','10.50.10.204:9997')

#get system details
$endpoint=[System.Net.Dns]::GetHostByName($env:computerName).HostName
#get/add other details? (domain, IP, etc)

#get splunk home
$splunk_home = (get-item env:\SPLUNK_HOME).value
Write-Output "hostname=$endpoint test=splunk_data value=splunk_home result=""$splunk_home"""
Start-Sleep -Seconds 2

#get deployclient file
$deploy_client_file=(. "$env:SPLUNK_HOME\bin\splunk.exe" btool --debug deploymentclient list) -match 'targetUri' -replace '\stargetUri.*$'
echo "hostname=$endpoint test=splunk_data value=deploy_client_conf_file result=""$deploy_client_file"""
sleep 2

$success_dns_count = 0
$total_dns_count = $dns_list.Count

#test each DNS entry
foreach ($dns in $dns_list){
    try{
        $dns_resolution = [System.Net.Dns]::GetHostAddresses($dns)
        $success_dns_count++
    }
    catch{
        $dns_resolution = "UNRESOLVED"
    }
    Write-Output "hostname=$endpoint test=dns_check value=$dns result=$dns_resolution"
    Start-Sleep -Seconds 2
}

#print DNS summary
Write-Output "hostname=$endpoint test=dns_summary value=$total_dns_count result=$success_dns_count"
Start-Sleep -Seconds 2

$success_connect_count = 0
$total_connect_count = $connect_list.Count

#test each network entry
foreach ($connect in $connect_list){
    $split = $connect.Split(":")
    $ip = $split[0]
    $port = $split[1]
    $client = New-Object System.Net.Sockets.TcpClient
    try{
        $client.Connect($ip,$port)
        $connect_result = "SUCCESS"
        $success_connect_count++
    }
    catch{
        $connect_result = "FAIL"
    }
    Write-Output "hostname=$endpoint test=connectivity_check value=$connect result=$connect_result"
    Start-Sleep -Seconds 2
}

#print Connectivity summary
Write-Output "hostname=$endpoint test=connectivity_summary value=$total_connect_count result=$success_connect_count"
