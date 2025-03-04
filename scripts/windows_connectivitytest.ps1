#new connectivity test

#variables with items to test
$dns_list = @('splunk-umbrella.cyber.ray.com','depotds.rockwellcollins.com','splunk.utc.com','search.splunk.cert.ray.com')

$connect_list = @('splunk-umbrella.cyber.ray.com:8089','10.50.10.95:8089','splunk.cyber.ray.com:443','depotds.rockwellcollins.com:8089','10.165.78.32:9997','10.180.12.53:9997','138.126.126.50:9997','10.50.10.199:9997','10.50.10.202:9997','10.50.10.203:9997','10.50.10.204:9997','128.13.135.143:8089','128.13.135.141:9997','128.13.135.142:9997')

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

# SIG # Begin signature block
# MIIV+QYJKoZIhvcNAQcCoIIV6jCCFeYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUpu2PZdVngaoYGNEWPR/u6FN2
# Wc6gghJPMIIFfzCCA+egAwIBAgIEYQBFaTANBgkqhkiG9w0BAQsFADB6MRMwEQYK
# CZImiZPyLGQBGRYDY29tMRMwEQYKCZImiZPyLGQBGRYDcnR4MQwwCgYDVQQKEwND
# QXMxFDASBgNVBAsTC1NlcnZpY2VzLUczMSowKAYDVQQDEyFSYXl0aGVvbiBUZWNo
# bm9sb2dpZXMgU2VydmljZXMgQ0EwHhcNMjIwNDEyMTMxMDIwWhcNMzQwNzEyMTM0
# MDIwWjBcMRMwEQYKCZImiZPyLGQBGRYDY29tMRUwEwYKCZImiZPyLGQBGRYFYWR4
# cnQxFjAUBgoJkiaJk/IsZAEZFgZkZXZpY2UxFjAUBgNVBAMTDVJUWC1BRFgtVExT
# Q0EwggGiMA0GCSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQDL4bFToNfnBOG9BZL+
# k+Vwr4vdnNJilDIChVJzy+LOZSqIku0iJ3+uTkgZ4gbMLHrXSrjH3PcUUxM/iMMs
# 648F7hY9gVJORqAuwFSZEPVgavlJQCE6rSLt/6HoVHPA3v1aE4wZLLIj+/0oq20g
# 7aAvq4e0v6t+SU205v3UeHaSoTaHTiQ/KFlvidWCuwQVkuQU++pAXaC2lvxGPH+3
# s8TrLTuv2GxbaYeQ83MrvYHY9mZllYWZh1A2jRjbJgihSFKuef8Lq3UeHRYeB8h9
# SFCv6pwSwIWQDVFbx4tnPBnq66KPSSnZSVXnSEPCDbqRLzV9hzTdC6Ka+iZcQa5l
# fL9EAValf6eVeD3QX7P3iX1D2K2eI56t4nUomYoz2NbR1oY/3Yu1klAHpGytSQzo
# ZtX4t4wCCRfTuw9L5wkR5xR3muoxWgGYpQiqClH0kKj7LNdRvnAUNJM5PrJM4T8q
# QtBjHePtEvAghVk/9i3bJ0SNwXyaiZgVCOEnSMOGG+Hf8UECAwEAAaOCASkwggEl
# MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/AgEAMBgGA1UdIAQRMA8w
# DQYLKwYBBAGB0REKAREwSAYIKwYBBQUHAQEEPDA6MDgGCCsGAQUFBzAChixodHRw
# Oi8vcGtpLnJ0eC5jb20vRzMvYWlhL1NlcnZpY2VzLUczXzAxLnA3YzAdBgNVHQ4E
# FgQUTY+DG0f1CAJXJbG1vCGOEItyTZIwQAYDVR0fBDkwNzA1oDOgMYYvaHR0cDov
# L3BraS5ydHguY29tL0czL0NSTHMvU2VydmljZXMtRzNfRnVsbC5jcmwwHwYDVR0j
# BBgwFoAUyE85UbJHzIMznx4FYTGvWBz1E2owGQYJKoZIhvZ9B0EABAwwChsEVjgu
# MgMCAIEwDQYJKoZIhvcNAQELBQADggGBAGQk7btSV8uHZbBWCYlL7bxV0rMfUv2i
# b95/EQZU5tDKsAO/HTRmIDGcuGAsfNGhWerl0Yv+JsvtH65+wTahfBqRb+OdSObD
# VGuB0S08v26/ymA3fbnDYfsig1rQsFO6jnnta5rzZ6MVMCUJa8RzghuM3sToMHpX
# RxvQEmwXp4nM27D38Tlu9yzrgh+xGS2OCInhc9qjhJlMndUnl45EJ9Ty2XUXyUCD
# ndqBjS72yJkttvDZsoDRQXyJxnqOgmq6ZQChv9tkLgopRvi3+T2Yv73w/uDgfYOP
# cKzO/0Yta/HE67xBBORbsEKm8laHPfQgwEcfK6CfpVeWoo2Y8l/lUdpgDTQrj9lv
# 0MM/h0uLyl3lkXcWiMWTF9iFIRVw1jba618A2hNqIK656vjyo+IEySspH9qdagit
# 31huq6rbewcrD/8XbxrSE1s01ACxtyZIEJHO47vamjFq62zPWTtVRzVbkw6lZsJn
# UhKrj6NjlHIgiqWvzXU0TQQ/XjDKF/bpuTCCBf4wggPmoAMCAQICBF+HToIwDQYJ
# KoZIhvcNAQELBQAwcjETMBEGCgmSJomT8ixkARkWA2NvbTETMBEGCgmSJomT8ixk
# ARkWA3J0eDEMMAoGA1UEChMDQ0FzMRAwDgYDVQQLEwdSb290LUczMSYwJAYDVQQD
# Ex1SYXl0aGVvbiBUZWNobm9sb2dpZXMgUm9vdCBDQTAeFw0yMTA3MjcxODM3Mzha
# Fw0zNDA3MjcxOTA3MzhaMHoxEzARBgoJkiaJk/IsZAEZFgNjb20xEzARBgoJkiaJ
# k/IsZAEZFgNydHgxDDAKBgNVBAoTA0NBczEUMBIGA1UECxMLU2VydmljZXMtRzMx
# KjAoBgNVBAMTIVJheXRoZW9uIFRlY2hub2xvZ2llcyBTZXJ2aWNlcyBDQTCCAaIw
# DQYJKoZIhvcNAQEBBQADggGPADCCAYoCggGBAPcDom+ARx6xFbKgALEuvRGbu42r
# wliBAdFZk4XRtZwfBT5yG548AJneShjXE8FMViuiC/i3EZAapgXvNMwUaEPpySot
# dPghqiajJpG/TXRn9xEehrUFpJ3TV3k698Cu7lssGxyw/k8it6MxQQQSMlsAG3zV
# 9E+gm/iqx3e/iTgnlWF9k7Z0xEr80MM6PtBSeQpb4TKMK6Y4YQxh2tpaPM9RnnIE
# T2HwnQeoT35m5cGPwxuI1/63zx9yM1rhyRzuBTmNqZAWIhaU7uRhxaGJovIoH9uR
# ppFu84TUGW8brQk8xnhFIk1AlCFki/uoLr2yWz6m/yHRScFOoo3ftR7QpjAL0SLI
# qjf6E/rp/qwBFQk2qaExyZwpEZGUctw45L5h3hStiuGQ6kFUKMywZ8DIEZSUTO2Y
# lUfkWqewVDrc0NxPEOBX6+4n4355zJONN2o9rUK/FuOLaMNHJejtoICnWULUUyD9
# rF5hGX7jKh31dplkk6hnrzzJm+AjF+i9BsWUMQIDAQABo4IBEjCCAQ4wDgYDVR0P
# AQH/BAQDAgEGMA8GA1UdEwEB/wQFMAMBAf8wRAYIKwYBBQUHAQEEODA2MDQGCCsG
# AQUFBzAChihodHRwOi8vcGtpLnJ0eC5jb20vRzMvYWlhL1Jvb3QtRzNfMDEucDdj
# MCcGA1UdIAQgMB4wDQYLKwYBBAGB0REKARAwDQYLKwYBBAGB0REKAREwPAYDVR0f
# BDUwMzAxoC+gLYYraHR0cDovL3BraS5ydHguY29tL0czL0NSTHMvUm9vdC1HM19G
# dWxsLmNybDAfBgNVHSMEGDAWgBRVNsuVIgJ9Qc3/WCq6z550qc3EGDAdBgNVHQ4E
# FgQUyE85UbJHzIMznx4FYTGvWBz1E2owDQYJKoZIhvcNAQELBQADggIBACFcQB3Y
# xVfIDZn/bDdxlfzG80P2g018PZK7ps6QMvZFM5NOeKc7mUP9+ynHivi5YPSvFTEb
# 7pugvediv5ki5HnDz3cewMUNibOzj35ZT0mIJ/xPL2EhHXYvFECSMWWSbPmf9Abb
# TiIUdeY+BSGsKdlM5Lyg/WY6VZ62bHxo42WUMUlf4r9vzO+hfsfmnuklPf0CN90D
# 9w3HUoxqzHD1xaq+KsRyfrXzyBbP9AuSeq8qj53MMVzSu4ovRrTCpO2Ly7FJJVWj
# CPkgwohIsYZbXbtbI+CYDDeSIL3qbBvn4QON5M6y1T8tQCUzfZwkyZGa9P6RtS3t
# GWphKpftY3P9c7nVhNG4MQiwYhLyG0GK7Spbx4jjXAY2uBz8Y2aLMJKE+4xrk6so
# sTjunfaB+i50MYEZ/9SF8AHOHMbwniMlufKWDClHYMmqNLI4K0XYbMGfi1vqPE9a
# yauXFah0DYdVtl/E21shx8yEpCleBQgnYCcNT8DXH3ouzneG+vKRZqmBXZKpwecH
# dl2E9sklcs/P7alsw83z5Q6C/dJjwSnNmIdQd8p8SqZSbMA11H0qHcNBS6YHsyn9
# e0tt8ZnVMGQSsclnUqVn3QBtsM+4RADnlt1s/X6Q8eh4LvrXG+7h5g/kQQSnA7Pa
# sFCScMEICqrr3wHiluwNJI1I9LUveTXWwXYBMIIGxjCCBS6gAwIBAgITfgAAEyVl
# MHp9om/3YQAAAAATJTANBgkqhkiG9w0BAQsFADBcMRMwEQYKCZImiZPyLGQBGRYD
# Y29tMRUwEwYKCZImiZPyLGQBGRYFYWR4cnQxFjAUBgoJkiaJk/IsZAEZFgZkZXZp
# Y2UxFjAUBgNVBAMTDVJUWC1BRFgtVExTQ0EwHhcNMjMwNzI0MTUxODU1WhcNMjUw
# NzI0MTUyODU1WjCBmzELMAkGA1UEBhMCVVMxFjAUBgNVBAgTDU1hc3NhY2h1c2V0
# dHMxEDAOBgNVBAcTB1dhbHRoYW0xHjAcBgNVBAoTFVJheXRoZW9uIFRlY2hub2xv
# Z2llczEhMB8GA1UEAxMYUlRYIENERSBTSUVNIEVuZ2luZWVyaW5nMR8wHQYJKoZI
# hvcNAQkBFhBjZGVfc2llbUBydHguY29tMIICIjANBgkqhkiG9w0BAQEFAAOCAg8A
# MIICCgKCAgEAtdseHy6zgAAlLx414xrPF62E6LAidIJkEv/R0wvgUFkCAh/B7viE
# JCja8oJqvJ033dnoDkU8reI6acYjoo4P2h4aZuoyEaBskUSShzWLYdAD5ddSn1KM
# JaszjJnVBMYHw9zHfmVGXie8MwfgITU7WnAirg7R21Dc14XqH66P74v1Kx6a6LB/
# WBlCMurhqTAmd5+O0NTEW8FopRgPFcaCUmFmZUeVLZrEsVvTJ5NMlOPYdK7CAqGJ
# iEFj1DCA3vkp+qOW/cRTzIhfWOUbYVXIn6WXOfw+Rkf5YtsYpxA21IQwPwdpsh38
# 6SbjzP+0fuJsS5IOgeDOSyqy8AeGrxA8cZra6+0GUfkknEXsiE8Er3lj83jSRbVU
# GYRnLfI0VCaG1RBFHXbzb86lOc1OMGZa7vaYuYwNA19Y3O1s8njcUxxOQ9F2UvKb
# obVLL51ItDK1zJyvOfahKfvkKfoS3QipmH6sYEOoofa5Kq9BTiWCBTpK4ofsZrrq
# cQYFQDh8iy6O5JbCRYzAjcB9WtjIO3sxIRmz/dmpCnt9n6qPtVQWjlLR/qI8CpgE
# uHXMzz5gg8bIsqWFhZ+Z6mJeJAsjZyEFaUEoM4266mRvRjMUFWeTFVS97PF3ndMo
# 049DiAFUtaJ+Pg+nAGZ0odv4AyQ0kF0O0/7wSFmgBH5fqdsVi8zcJikCAwEAAaOC
# Ab8wggG7MB0GA1UdDgQWBBQ5veSnd9weBU+B179YXip4BZlm7DAfBgNVHSMEGDAW
# gBRNj4MbR/UIAlclsbW8IY4Qi3JNkjBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8v
# cGtpLnJ0eC5jb20vRzMvQ1JMcy9SVFgtQURYLVRMU0NBX0Z1bGwuY3JsMG0GCCsG
# AQUFBwEBBGEwXzA3BggrBgEFBQcwAoYraHR0cDovL3BraS5ydHguY29tL0czL2Fp
# YS9SVFgtQURYLVRMU0NBLmNydDAkBggrBgEFBQcwAYYYaHR0cDovL3BraS5ydHgu
# Y29tL29jc3AvMA4GA1UdDwEB/wQEAwIGwDA7BgkrBgEEAYI3FQcELjAsBiQrBgEE
# AYI3FQiFp/ZKhJTnKYa9nSqTtiviwgaBZIf4oSrmklMCAWQCAQ0wEwYDVR0lBAww
# CgYIKwYBBQUHAwMwGwYJKwYBBAGCNxUKBA4wDDAKBggrBgEFBQcDAzBHBgNVHSAE
# QDA+MDwGCysGAQQBgdERCgERMC0wKwYIKwYBBQUHAgEWH2h0dHBzOi8vcGtpLnJ0
# eC5jb20vaW5mb3JtYXRpb24wDQYJKoZIhvcNAQELBQADggGBAKzwB40TfMVKboaL
# FR7dRvxy+4P+cBOOEKS+kNf8AwACSm4cLCSNB3VqQ1QsrDpjFIg4GyEAYYirhswt
# bRdDF5FtQe+NvWtnNE4jtbX6fcXlOyfB1X7kh4SYUQ+d0IXTtcM/I1Fs+Ya6Dpte
# fP3GN9DPjzoRe/FhBycdXLrRPtnZPmcVuclrPHOZDdxFmB/BXcHuxik3f3knAN30
# YufKOpQnZe/GDXfY68NCb5ry2DRB4QMUfInBnzA7/6YULlyQoGZg5AlMBOoDJxnX
# oYv5JjYMB1jal9lEpC1PPx8P888rh9KVxUTFZX4FUF5nHBXbRiXQdcRwaAWrH8dY
# 0VsBuIkTyOUzkZ2YiaM4QVtse8yiZ3u3+vWX6Vmla/LkXlvFt43XASa22NbANbW9
# m5HdruirReSqFns8wN9kNu2VAiN1VgUz/rfXjGGqyMSireOmvV+mj57hFfDhOXut
# +V9g/aG/3uhTGLpfiT7h+IOwLO7QXnwFQ73caKfQb9vRupj84TGCAxQwggMQAgEB
# MHMwXDETMBEGCgmSJomT8ixkARkWA2NvbTEVMBMGCgmSJomT8ixkARkWBWFkeHJ0
# MRYwFAYKCZImiZPyLGQBGRYGZGV2aWNlMRYwFAYDVQQDEw1SVFgtQURYLVRMU0NB
# AhN+AAATJWUwen2ib/dhAAAAABMlMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBS3BE211LuY1bGM
# wJ4VlwO+6iwIkjANBgkqhkiG9w0BAQEFAASCAgAIxdhWPhfHs6nV6g6zbqWQ6Itb
# uh5G15wsCODJ2vMh+bIYLij/efPUmxi4/NPx+khCvWvxYxdIhHM8QL9iqgmo8rZW
# JyqHcmCrTcPXL6Q9bTOGaqZy79q0NY94dPnAq52UH0HDk8HlkMsnDh/q3sYFFOij
# sv6NwP5qGC0jedr9kZKtttCCzyj7lzGK5LEC/Ox2jz0H6XFS/Rv+Myb0pqEZeKm2
# ZcGbMSCJsTSY3/ISb771vSUsenQxGQf+lItOQp8ia2QMqZtMHmr5/79vxgeZXxJw
# qpj8Ux1IaPjnYlhr3oZCMAeBZwErngI/nd2/7QxU2IvNv2HevLIp7ev2RLh2vaG9
# RaUfGTpjN9GOxLxV1MJToXw1B3L0L7tWMlGaWvSZ/42+msvKfKHiKT7Hj9BTWNPe
# yCeirKao7F5p6t8MzckRu5PVn4kLVnKHOzKXMNEJw6qXJ+EBOEANPWA0RmtbKked
# iV6qu/ab6ebpcgAyvyu6H48rxjoaGbUxnmSvrz/J7IJ60NhX80r+wFI+aivk7D/q
# jLFvAE37LdMiTFzb+oywYZEQ+3PwcNvle/HqTeY1Z2wonttNR+9OczUTTO74y/cf
# CWrv3BZXskjqlA3ujqzeJqtp0qR9x8PUfyjqdAUDhFaSNbzfCelnQJS2V9yOyYgK
# tNYDkfPJ+JWq/OIQUg==
# SIG # End signature block
