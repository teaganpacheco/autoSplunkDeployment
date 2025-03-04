# Powershell Script for Splunk Forwarder Windows Installation

# Variables
$searchVersion=Get-WmiObject -Class Win32_Product | Where-Object Name -eq UniversalForwarder | Select-Object Version
$versionInstalled=Write-Output $searchVersion | Select-String -Pattern "(\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+)" |  ForEach-Object { $_.Matches.Value }
$mode=$args[0]
$package=$args[1]
$environment=$args[2]


# Normalize Variables:
$mode=$mode.ToLower()
$package=$package -replace "\%2d","-"
$package=$package -replace "\%2e","."
$environment=$environment -replace "\%2e","."
$versionPackage=Write-Output $package | select-string -Pattern "(\d+\.\d+\.\d+\.\d+|\d+\.\d+\.\d+)" | ForEach-Object { $_.Matches.Value }

Write-Output ""
Write-Output "
-- Script Stats --
Current Version (if present): $versionInstalled
Selected Mode: $mode
Selected Package: ($versionPackage) $package
Destination Environment: $environment
"

# Function Section

# Remove (Complete)
function removeSplunk {
    Write-Output "Beginning Removal of Splunk"
    $app = Get-WmiObject -Class win32_product -Filter "Name = 'UniversalForwarder'" 
    $app.Uninstall()
    Start-Sleep 30
    if (Test-Path -Path 'C:\Program Files\SplunkUniversalForwarder') {
        Remove-Item -LiteralPath 'C:\Program Files\SplunkUniversalForwarder' -Force -Recurse
    }
    Write-Output "Removal of Splunk Forwarder Complete"
    exit 0
}

# Modify (Complete)
function modifySplunk {
    Write-Output "Begining Modification of Splunk"
    $service=Get-Service -Displayname "*Splunk*" | Select-Object Name
    $service=$service.Name
    Stop-Service -Name "$service"
    Start-Sleep 10

    Get-ChildItem "C:\Program Files\SplunkUniversalForwarder\etc\apps" -recurse | Where-Object {$_.name -eq "deploymentclient.conf"} | ForEach-Object { $_.Fullname } | Out-File -FilePath "C:\splTEMP.txt"
    $dc_files = Get-Content "C:\splTEMP.txt"
    foreach ($i in $dc_files) { Move-Item -Force $i $i".old" }
    Get-ChildItem "C:\Program Files\SplunkUniversalForwarder\etc\apps" -recurse | Where-Object {$_.name -eq "outputs.conf"} | ForEach-Object { $_.Fullname } | Out-File -FilePath "C:\splTEMP.txt"
    $dc_files = Get-Content "C:\splTEMP.txt"
    foreach ($i in $dc_files) { Move-Item -Force $i $i".old" }
    Remove-Item -LiteralPath "C:\splTEMP.txt"
    if (Test-Path -Path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf") {
       ( Get-Content -path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf" -Raw ) -replace 'targetUri','#targetUri' | Set-Content -Path "C:\Program Files\SplunkUniversalForwarder\etc\system\local\deploymentclient.conf"    }
    else {
        Write-Output "etc\system\local clean"
    }
    Remove-Item -Recurse -Force "C:\Program Files\SplunkUniversalForwarder\etc\apps\z_deploymentRedirect"
    New-Item -Path "C:\Program Files\SplunkUniversalForwarder\etc\apps" -Name "z_deploymentRedirect" -ItemType "directory"
    New-Item -Path "C:\Program Files\SplunkUniversalForwarder\etc\apps\z_deploymentRedirect" -Name "local" -ItemType "directory"
    Get-Content $environment > "C:\Program Files\SplunkUniversalForwarder\etc\apps\z_deploymentRedirect\local\deploymentclient.conf"
    Start-Sleep 10
    Start-Service -Name "$service"
    exit 0
}

# Upgrade (Complete)
function upgradeSplunk { 
    Write-Output "Beginning Upgrade of Splunk"
    $compare=[System.Version]"$versionInstalled" -ge [System.Version]"$versionPackage"
    Write-Output "
    Upgrade Version: $versionPackage
    Installed Version: $versionInstalled
    Version Comparison Error: $compare
    "
        if ( $compare -eq "True" ) {
            Write-Output "Installed Version is already ahead of Proposed Package"
            exit 1
        }
        else {
            $service=Get-Service -Displayname "*Splunk*" | Select-Object Name
            $service=$service.Name
            Stop-Service -Name "$service"
            Remove-Item -LiteralPath 'C:\Program Files\SplunkUniversalForwarder\etc\passwd'
            Write-Output "[user_info]" > "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
            Write-Output "USERNAME = admin" >> "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
            get-random > "C:\splTEMPrandom.txt"
            $password=(Get-FileHash -Algorithm sha256 "C:\splTEMPrandom.txt" | ForEach-Object { $_.Hash}).SubString(4,25)
            Remove-Item -LiteralPath "C:\splTEMPrandom.txt"
            Write-Output "PASSWORD = $password" >> "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
            msiexec.exe /i $package AGREETOLICENSE=yes LAUNCHSPLUNK=0 /quiet /norestart
            Start-Sleep 20
            if ([string]::IsNullOrWhiteSpace($environment)) { 
                Start-Service -Name "$service"
                Write-Output "Upgrade Complete, exiting"
                Start-Sleep 2
                exit 0
            }
            else {
                modifySplunk
            }
    }
}

# Install (Complete)
function installSplunk {
    Write-Output "Beginning Installation of Splunk"
    msiexec.exe /i  $package AGREETOLICENSE=yes LAUNCHSPLUNK=0 /quiet /norestart
    Start-Sleep 30
    Write-Output "[user_info]" > "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
    Write-Output "USERNAME = admin" >> "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
    get-random > "C:\splTEMPrandom.txt"
    $password=(Get-FileHash -Algorithm sha256 "C:\splTEMPrandom.txt" | ForEach-Object { $_.Hash}).SubString(4,25)
    Remove-Item -LiteralPath "C:\splTEMPrandom.txt"
    Write-Output "PASSWORD = $password" >> "C:\Program Files\SplunkUniversalForwarder\etc\system\local\user-seed.conf"
    modifySplunk
}

# Selection Section

if ($mode -eq "remove") {
    if ([string]::IsNullOrWhiteSpace($versionInstalled)) { 
            Write-Output "Splunk Does Not Exist, exiting Script"
            Start-Sleep 2
            exit 1
        }
    removeSplunk
}
elseif ($mode -eq "modify") {
    if ([string]::IsNullOrWhiteSpace($environment)) {
        Write-Output "Environment variable not defined; please define and redeploy"
        Start-Sleep 2
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($package)) {
        Write-Output "Package variable not defined; please define and redeploy"
        Start-Sleep 2
        exit 1
    }
    modifySplunk
}
elseif ($mode -eq "upgrade") {
    if ([string]::IsNullOrWhiteSpace($package)) {
        Write-Output "Package variable not defined; please define and redeploy"
        Start-Sleep 2
        exit 1
    }
    if ([string]::IsNullOrWhiteSpace($versionInstalled)) { 
        Write-Output "Splunk Does Not Exist, installing"
        Start-Sleep 2
        installSplunk
    }
    else {
        upgradeSplunk
        
    }
}
elseif ($mode -eq "install") {
      if(Test-Path -Path 'C:\Program Files\SplunkUniversalForwarder') {
          Write-Output "Splunk Already Exists; Aborting"
          Start-Sleep 2
          exit 1
      }
      else {
          installSplunk
      }
}
else {
    Write-Output "Command not recognized, please reselect parameters"
    exit 1
}


# SIG # Begin signature block
# MIIV+QYJKoZIhvcNAQcCoIIV6jCCFeYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMHvp3SmW8G7rONCDvUKy73go
# TQ2gghJPMIIFfzCCA+egAwIBAgIEYQBFaTANBgkqhkiG9w0BAQsFADB6MRMwEQYK
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
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBS4zo6l0bwqeaHn
# kSBs9JvBZ9cVjjANBgkqhkiG9w0BAQEFAASCAgALBD36s5wLiOctwU7yBM8xrptp
# +2LilL/tcQ0XI4DyzJwcXiarhBv8jOhYUKqExAZtNuAKczoP3EUrtdjGgLYltrGo
# q6C59W7RVS/ctwsCUHdADf34/GyAjFYKeRgmbjmXN1HqJg6CKPNlvB8GGYI4wc5A
# PaHmoRaoxo/+I5br908FFQnpdlzY27q9ISjIv7s6OFliB+Uav0n+t70TkDd/buK3
# q45LvreNC3/ZgXLiF+FyceCtCCOK4Kx/hOM88t2J4NJpdw/SezXxyfAVrPH65nvU
# 2Q1CbzNvtcUJuJmshC4ykp0d/XkAcuFsmpw3beerOu9HyjtqO+cQiLf6xpcQ1DXf
# LrYsfpx5nuwyDgKNX07bxFswe/YVX7hWzT20pQjijtPE076I3PvTQOFIieqgxyvq
# 2Zd3zlqooQb/eCpXXtuiXkiQsP7z2P6ub2ZXGdYqrfkFVsSbMhjcc7xbXAx6mvOm
# HLNyqJ8yh3MmhljFrlhXjnLDD+/bLs4IId3c/7r/10QPqXtew81X/juXTaISSIE/
# hhgeKesvVSwhRPdMKQtH2j6hyYnzcFoiqZhcdCKzjdPHbw7qP1ysu2SrKYlYP/lr
# dz9DaVAE8GgTNU4HTrRkRyc1e/e/cVG88fFJ5Eci14t1Y6EQlpdKLraO/BdfGY6O
# A1g854KAoGYLeawCYQ==
# SIG # End signature block
