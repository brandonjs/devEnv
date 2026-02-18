#!/bin/bash - 
#===============================================================================
#
#          FILE: fix_firewall_ssh.sh
# 
#         USAGE: ./fix_firewall_ssh.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 08/17/2022 12:53:10
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

#
# Insert into /etc/pf.conf
# block return in proto tcp from any to any port 22
# pass in inet proto tcp from 192.168.1.0/24 to any port 22 no state
#
while true; do
  pfctl -f /etc/pf.conf
  sleep 10
done

