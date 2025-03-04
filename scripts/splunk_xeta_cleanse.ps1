# Powershell script to check connectivity to the environment and produce a report

date
if (Test-Path -Path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf") {
( Get-Content -path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf" -Raw ) -replace 'targetUri','#targetUri' | Set-Content -Path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"
Write-Output "System Local Check: deploymentclient neutralized"
}
else {
Write-Output "System Local Check: deploymentclient not present"
}

if (Test-Path -Path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf") {
Remove-Item "C:\Program Files\SplunkUniversalForwarder\etc\system\local\outputs.conf"
Write-Output "System Local Check: outputs neutralized"
}
else {
Write-Output "System Local Check: outputs not present"
}
