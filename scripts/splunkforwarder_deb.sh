#!/bin/bash
# Shell Script for Splunk Forwarder DEB Installation
# Originally Designed for Tanium Interactions

# Variables
function fileDecode() {
	: "${*//+/ }"; echo -e "${_//%/\\x}";
}

versionInstalled=$(apt list --installed | grep -oe "splunkforwarder.*" | sed 's/.*\([[:digit:]]\.[[:digit:]]\.[[:digit:]]\.[[:digit:]]\|[[:digit:]]\.[[:digit:]]\.[[:digit:]]\).*/\1/g')
mode=$(echo $1 | awk '{print tolower($0)}')
package=$(fileDecode $2)
versionPackage=$(echo $package |  cut -f2 -d-)
environment=$(fileDecode $3)
location=$(dpkg --listfiles splunkforwarder | sed 's/splunkforwarder.*/splunkforwarder/g' | grep splunkforwarder | uniq)
splkuser=$(stat -c %U $location)
splkgroup=$(stat -c %G $location)
service=$(cat $location/etc/splunk-launch.conf | grep SPLUNK_SERVER_NAME | sed 's/.*\=\(.*\)/\1\.service/g')
 
echo 
echo "
-- Script Stats --
Current Version (if present): $versionInstalled
Selected Mode: $mode
Selected Package: ($versionPackage) $package
Destination Environment: $environment
Splunk Location: $location
Splunk User and Group: $splkuser:$splkgroup
Service File: $service
"
echo

# Function Section


function varlogSplunk() {
    if [ -z "$splkuser" ]; then {
        splkuser="splunk"
    }
    fi

    setfacl -m u:$splkuser:--x,g:$splkuser:--x /var/log
    setfacl -m u:$splkuser:r--,g:$splkuser:r-- /var/log/messages
    setfacl -m u:$splkuser:r--,g:$splkuser:r-- /var/log/secure
    setfacl -m u:$splkuser:r--,g:$splkuser:r-- /var/log/syslog
    setfacl -m u:$splkuser:r--,g:$splkuser:r-- /var/log/auth.log
    setfacl -m u:$splkuser:r--,g:$splkuser:r-- /var/log/faillog

}


# Remove (Complete)
function removeSplunk() {
    echo "Beginning Removal of Splunk"
    target=$(apt list --installed | grep -oe "splunkforwarder.*" | sed 's/\/.*//g')
        su - $splkuser -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk stop'
        $location/bin/splunk disable boot-start
        dpkg -P $target
        rm -rf $location
        echo "Removal of Splunk Forwarder Complete"
}

# Modify
function modifySplunk() {
    echo "Beginning Modification of Splunk"

    find $location/etc/apps -name deploymentclient.conf > /tmp/splFiles.txt
    for i in `cat /tmp/splFiles.txt`; do mv ${i} ${i}.old; done;
    find $location/etc/apps -name outputs.conf > /tmp/splFiles.txt
    for i in `cat /tmp/splFiles.txt`; do mv ${i} ${i}.old; done;
    rm -f /tmp/splFiles.txt

    varlogSplunk

    mkdir -p $location/etc/apps/z_deploymentRedirect/local
    cat $environment >> $location/etc/apps/z_deploymentRedirect/local/deploymentclient.conf
    chown -R $splkuser:$splkgroup $location
    su - $splkuser -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk restart'
}

# Upgrade (Complete)
function upgradeSplunk() {
    echo "Beginning Upgrade of Splunk"
    echo "$versionPackage" > /tmp/splkVersions
    echo "$versionInstalled" >> /tmp/splkVersions
    check=$(cat /tmp/splkVersions | sort -V | tail -1)
    rm -f /tmp/splkVersions
    if [ "$check" == "$versionInstalled" ]; then {
        echo "A higher version of Splunk is already installed"
        exit 1
    }
    else {
        su - $splkuser -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk stop'
        $location/bin/splunk disable boot-start
        rm -f $location/etc/passwd
        echo "[user_info]" > $location/etc/system/local/user-seed.conf
        echo "USERNAME = admin" >> $location/etc/system/local/user-seed.conf
        password=$(date +%s | sha256sum | base64 | head -c 22 ; echo)
        echo "PASSWORD = $password" >> $location/etc/system/local/user-seed.conf
        chown -R $splkuser:$splkgroup $location
        dpkg -i $package
        su - splunk -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk start --accept-license --answer-yes'
        sleep 10
        su - splunk -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk stop'
    }
    fi

    if [ -z "$environment" ]; then {
        $location/bin/splunk enable boot-start -user $splkuser -systemd-managed 0 --accept-license --answer-yes
        su - splunk -c 'location=$(dpkg --listfiles splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | grep splunkforwarder | uniq) &&  $location/bin/splunk start' 
        echo "Upgrade Complete, exiting"
        sleep 2
        exit 0
    }
    else {
        modifySplunk
    }
    fi
}

# Install (Complete)
function installSplunk() {
    if [ "$package" == "none" ] || [ "$environment" == "none" ]; then {
        echo "No Package or Environment Selected; These are prerequistes for installation. Aborting installation"
        exit 1
    }
    fi
    if  test -f "$location/etc/splunk.version" ; then {
        echo "There is already an installation present; aborting installation. Please use Upgrade"
        exit 1
    }
    fi
    echo
    echo "Begining Installation of Splunk Forwarder"
    dpkg -i $package
    echo "[user_info]" > /opt/splunkforwarder/etc/system/local/user-seed.conf
    echo "USERNAME = admin" >> /opt/splunkforwarder/etc/system/local/user-seed.conf
    splkPass=$(date +%s | sha256sum | base64 | head -c 18)
    echo "PASSWORD = $splkPass" >> /opt/splunkforwarder/etc/system/local/user-seed.conf
    mkdir -p /opt/splunkforwarder/etc/apps/z_deploymentRedirect/local
    cat $environment >> /opt/splunkforwarder/etc/apps/z_deploymentRedirect/local/deploymentclient.conf
    chown -R splunk. /opt/splunkforwarder
    /opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 0 --accept-license --answer-yes
    su - splunk -c '/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes'

    varlogSplunk
    echo 
    echo "
    Your Installation Is Complete"
}

# Selection Section
if [ $mode == "remove" ]; then {
    if [ ! -f $location/etc/splunk.version ]; then {
        echo "Splunk Does Not Exist, Exiting Script"
        sleep 2
        exit 1
    }
    fi
    removeSplunk
}
elif [ $mode == "modify" ]; then {
    if [ -z "$environment" ]; then {
        echo "Environment variable not defined; please define and redeploy"
        sleep 2
        exit 1
    }
    fi
    if [ -z "$package" ]; then {
        echo "Package variable not defined; please define and redeploy"
        sleep 2
        exit 1
    }
    fi
    modifySplunk
}
elif [ $mode == "upgrade" ]; then {
    if [ -z "$package" ]; then {
        echo "Package variable not defined; please define and redeploy"
        sleep 2
        exit 1
    }
    fi
    if [ ! -f $location/etc/splunk.version ]; then {
        echo "Splunk Does Not Exist; exiting"
        sleep 2
        exit 1
    }
    else {
    upgradeSplunk
    }
    fi
}
elif [ $mode == "install" ]; then {
    if [ -f "$location/etc/splunk.version" ]; then {
        echo "Splunk Already Exists; Aborting"
        sleep 2
        exit 1
    }
    fi
    installSplunk
}
else {
    echo "Command not recognized. Please define and redeploy"
}
fi
