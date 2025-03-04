#!/bin/sh

set -e

useradd -m -U splunk

echo "splunk:sysadmin01" | chpasswd 

sudo usermod -aG sudo splunk

cd /home/splunk

sudo mkdir .ssh/

sudo chown -R splunk. /home/splunk/.ssh

cd .ssh/

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzju2SHNQhYLPuAfaSqkoUV04e636Dg4P0uPw7IzWbF github

ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMg/UHcB6sQ8eMcjdyaGx+FM+2swJPYSm6EXkJHm08fq splunk" > authorized_keys

sudo chown splunk. authorized_keys

sudo chmod 664 authorized_keys
