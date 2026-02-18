#!/bin/bash

domains="msn4.amazon.com
aka.amazon.com
ant.amazon.com
amazon.com"
#device=$1

hardwarePorts=`sudo networksetup -listallnetworkservices`
OLDIFS=$IFS
IFS=$'\n'
for i in $hardwarePorts; do

if [[ "$i" == *Ethernet* ]] || [[ "$i" = "Wi-Fi" ]]; then
   sudo networksetup -setsearchdomains "$i" $domains
fi

done
IFS=$OLDIFS
