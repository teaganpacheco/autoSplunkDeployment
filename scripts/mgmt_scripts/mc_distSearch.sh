#!/bin/bash

cd inventory/; touch tmpHosts.list; cd ../; ansible searchheads -m gather_facts | grep -i ansible_fqdn | cut -f2 -d: | tr -d '",' > inventory/tmpHosts.list
