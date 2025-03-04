#!/bin/bash
# Shell Script for Splunk Forwarder RHEL Installation
# Originally Designed for Tanium Interactions


# Variables
function fileDecode() {
	: "${*//+/ }"; echo -e "${_//%/\\x}";
}

versionSearch=$(rpm -qa | grep splunkforwarder | head -1)
versionInstalled=$(echo $versionSearch | sed "s/splunkforwarder-//g" | sed "s/-.*//g")
mode=$(echo $1 | awk '{print tolower($0)}')
package=$(fileDecode $2)
versionPackage=$(echo $package |  cut -f2 -d-)
environment=$(fileDecode $3)
rhel=$(cat /etc/redhat-release |grep -oE "release [[:digit:]]" | sed 's/release //g')
location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq)
splkuser=$(stat -c %U $location)
splkgroup=$(stat -c %G $location)
service=$(cat $location/etc/splunk-launch.conf | grep SPLUNK_SERVER_NAME | sed 's/.*\=\(.*\)/\1\.service/g')

if [ -z "$rhel" ]; then {
    rhel="7"
}
fi

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
    target=$(rpm -qa | grep splunkforwarder)
    if [ "$rhel" -ge 7 ] && test -f "/etc/systemd/system/$service" ; then {
        systemctl stop $service
        $location/bin/splunk disable boot-start
        rpm -e $target
        rm -rf $location
        echo "Removal of Splunk Forwarder Complete"
        }
    elif [ "$rhel" -ge 7 ]; then {
        su - $splkuser -c 'location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk stop'
        rpm -e $target
        rm -f /etc/init.d/splunk
        rm -rf $location
        echo "Removal of Splunk Forwarder Complete"
    }
    elif [ "$rhel" -lt 7 ]; then {
        su - $splkuser -c 'location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk stop'
        $location/bin/splunk disable boot-start
        rpm -e $target
        rm -f /etc/init.d/splunk
        rm -rf $location
        echo "Removal of Splunk Forwarder Complete"
    }
    fi
}

# Modify (Complete)
function modifySplunk() {
    echo "Beginning Modification of Splunk"
    if [ "$rhel" -ge 7 ] && test -f "/etc/systemd/system/$service" ; then {
        systemctl stop $service
        $location/bin/splunk disable boot-start
    }
    elif [ test -f "/etc/init.d/$service" ]; then {
        $location/bin/splunk stop
        $location/bin/splunk disable boot-start
    }
    fi
    find $location/etc/apps -name deploymentclient.conf > /tmp/splFiles.txt
    for i in `cat /tmp/splFiles.txt`; do mv ${i} ${i}.old; done;
    find $location/etc/apps -name outputs.conf > /tmp/splFiles.txt
    for i in `cat /tmp/splFiles.txt`; do mv ${i} ${i}.old; done;
    rm -f /tmp/splFiles.txt
    mkdir -p $location/etc/apps/z_deploymentRedirect/local
    cat $environment >> $location/etc/apps/z_deploymentRedirect/local/deploymentclient.conf
    chown -R $splkuser:$splkgroup $location

    varlogSplunk

    if [ "$rhel" -ge 7 ]; then {
        $location/bin/splunk enable boot-start -user $splkuser -systemd-managed 1 -systemd-unit-file-name splunkforwarder --accept-license --answer-yes
        systemctl start splunkforwarder
    }
    elif [ "$rhel" -lt 7 ]; then {
        $location/bin/splunk enable boot-start -user $splkuser -systemd-managed 0 --accept-license --answer-yes
        su - splunk -c "location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk start"
    }
    fi
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
        if [ "$rhel" -ge 7 ] && test -f "/etc/systemd/system/$service" ; then {
            systemctl stop $service
            $location/bin/splunk disable boot-start

        }
        elif [ test -f "/etc/init.d/$service" ]; then {
            $location/bin/splunk stop
            $location/bin/splunk disable boot-start
        }
        fi
        rm -f $location/etc/passwd
        echo "[user_info]" > $location/etc/system/local/user-seed.conf
        echo "USERNAME = admin" >> $location/etc/system/local/user-seed.conf
        password=$(date +%s | sha256sum | base64 | head -c 22 ; echo)
        echo "PASSWORD = $password" >> $location/etc/system/local/user-seed.conf
        chown -R $splkuser:$splkgroup $location
        rpm -Uvh $package
        su - splunk -c 'location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk start --accept-license --answer-yes'
        sleep 10
        su - splunk -c 'location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk stop'
    }
    fi

    if [ -z "$environment" ]; then {
        if [ "$rhel" -ge 7 ]; then {
            $location/bin/splunk enable boot-start -user $splkuser -systemd-managed 1 -systemd-unit-file-name splunkforwarder --accept-license --answer-yes
            systemctl start splunkforwarder
        }
        elif [ "$rhel" -lt 7 ]; then {
            $location/bin/splunk enable boot-start -user $splkuser -systemd-managed 0 --accept-license --answer-yes
            su - splunk -c "location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq) && $location/bin/splunk start"
        }
        fi        
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
    location=$(rpm -ql splunkforwarder | sed "s/splunkforwarder.*/splunkforwarder/g" | uniq)
    if  test -f "$location/etc/splunk.version" ; then {
        echo "There is already an installation present; aborting installation. Please use Upgrade"
        exit 1
    }
    fi
    echo
    echo "Begining Installation of Splunk Forwarder"
    useradd -m splunk
    rpm -i $package
    echo "[user_info]" > /opt/splunkforwarder/etc/system/local/user-seed.conf
    echo "USERNAME = admin" >> /opt/splunkforwarder/etc/system/local/user-seed.conf
    splkPass=$(date +%s | sha256sum | base64 | head -c 18)
    echo "PASSWORD = $splkPass" >> /opt/splunkforwarder/etc/system/local/user-seed.conf
    mkdir -p /opt/splunkforwarder/etc/apps/z_deploymentRedirect/local
    cat $environment >> /opt/splunkforwarder/etc/apps/z_deploymentRedirect/local/deploymentclient.conf
    chown -R splunk. /opt/splunkforwarder
    if [ "$rhel" -ge 7 ]; then {
        /opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 1 -systemd-unit-file-name splunkforwarder --accept-license --answer-yes
    }
    elif [ "$rhel" -lt 7 ]; then {
        /opt/splunkforwarder/bin/splunk enable boot-start -user splunk -systemd-managed 0 --accept-license --answer-yes
    }
    fi

    if [ "$rhel" -ge 7 ]; then {
        systemctl start splunkforwarder
    }
    elif [ "$rhel" -lt 7 ]; then {
        su - splunk -c '/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes'
    }
    fi
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
