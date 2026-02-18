#!/bin/bash

# Simple script for greylisting the IP addresses contained in a CIDR netblock.

cidr=`ip route show | awk '/proto/{print $1}'`
netmask=~/netmask
#ipaddress=`$PING -c 1 -w 1 $ans_hostname | grep 'bytes of data' | sed -e 's/.*(\([[:digit:]]\{1,3\}\(\.[[:digit:]]\{1,3\}\)\{3\}\)).*/\1/g' -e 's/\.[0-9]*$/ /g'`
ipaddress=(`ping -c 1 -w 1 solace | grep 'bytes of data' | sed -e 's/.*(\([[:digit:]]\{1,3\}\(\.[[:digit:]]\{1,3\}\)\{3\}\)).*/\1/g' -e 's/\\./ /g'`)
ipsa=${ipaddress[0]}
ipsb=${ipaddress[1]}
ipsc=${ipaddress[2]}
ipsd=${ipaddress[3]}

array1=( `$netmask $cidr -r | sed "s/^ *//" | cut -d "-" -f 1 | sed 's/\\./ /g'` )
array2=( `$netmask $cidr -r | sed "s/^ *//" | cut -d "-" -f 2 | sed 's/\\./ /g'` )

a1=${array1[0]}
b1=${array1[1]}
c1=${array1[2]}
d1=${array1[3]}

a2=${array2[0]}
b2=${array2[1]}
c2=${array2[2]}
d2=${array2[3]}

echo "# Network cidr: $cidr"
echo "# Network range: $a1.$b1.$c1.$d1 - $a2.$b2.$c2.$d2"
echo "# Ipaddress: $ipsa.$ipsb.$ipsc.$ipsd"

if [[ ! $ipsa -ge $a1 || ! $ipsa -le $a2 ]]
then
   echo "ERROR: $ipsa is not in network $cidr."
   exit 1
fi

if [[ ! $b2 -eq 255 || ! $b1 -eq 0 ]]; then
   if [[ ! $ipsb -ge $b1 || ! $ipsb -le $b2 ]]
   then
      echo "ERROR: $ipsa.$ipsb is not in network $cidr."
      exit 1
   fi
fi

if [[ ! $c2 -eq 255 || ! $c1 -eq 0 ]]; then
   if [[ ! $ipsc -ge $c1 || ! $ipsc -le $c2 ]]
   then
      echo "ERROR: $ipsa.$ipsb.$ipsc is not in network $cidr."
      exit 1
   fi
fi

if [[ ! $d2 -eq 255 || ! $d1 -eq 0 ]]; then
   if [[ ! $ipsd -ge $d1 || ! $ipsd -le $d2 ]]
   then
      echo "ERROR: $ipsa.$ipsb.$ipsc.$ipsd is not in network $cidr."
      exit 1
   fi
fi

exit

