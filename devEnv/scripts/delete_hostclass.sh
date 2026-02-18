#!/bin/bash

hostClass=$1
[ -z $hostClass ] && echo "You must provide a hostclass to delete!" && exit 1
email=$2
[ -z $email ] && email="nobody@amazon.com"
kcurl -X POST -F 'formstate=2' -F "hostclass=$hostClass" -F "contact_email=$email" https://infrastructure.amazon.com/automation/deleteHostclass.cgi
