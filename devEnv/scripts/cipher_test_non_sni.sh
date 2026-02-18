#!/usr/bin/env bash

if [ "$#" -ne 1 ]
then
    echo "usage: $0 <dns/ip>:<port>"
fi

# OpenSSL requires the port number.
#SERVER=$1
IFS=':' read -a myarray <<< "$1"
SERVER=${myarray[0]}
PORT=${myarray[1]}

DELAY=0

echo "Checking default negotiation:"
echo -n | openssl s_client -connect $SERVER:$PORT 2>&1 | egrep '(  Protocol|  Cipher)'

ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')

echo
echo "Available Ciphers:"


for cipher in ${ciphers[@]}
do
result=$(echo -n | openssl s_client -cipher "$cipher" -connect $SERVER:$PORT 2>&1)
if [[ "$result" =~ "Cipher is ${cipher}" || "$result" =~ "Cipher    :" ]] ; then
  echo "$cipher ENABLED"
fi
sleep $DELAY
done
