#!/bin/bash - 
#===============================================================================
#
#          FILE: waltersm_l6.sh
# 
#         USAGE: ./waltersm_l6.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 06/06/2022 07:36:04
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

MANAGER=waltersm
#for i in $(/usr/bin/ldapsearch -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub uid=$MANAGER amznmanageremployees | awk -F: '{ if($1 ~ /amznmanageremployees/)  print $2}' | sed 's/.*(\(.*\)).*/\1/' ); do
for i in $(/usr/bin/ldapsearch -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub uid=$MANAGER amznmanageremployees | awk -F: '{ if($1 ~ /amznmanageremployees/)  print $2}'); do
   /usr/bin/ldapsearch -LLL -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub "(&(manager=$i)(amznjobcode=6))" uid amznjobcode
  for j in $(/usr/bin/ldapsearch -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub uid=$i amznmanageremployees | awk -F: '{ if($1 ~ /amznmanageremployees/)  print $2}' | sed 's/.*(\(.*\)).*/\1/' ); do
    /usr/bin/ldapsearch -LLL -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub uid=$j amznjobcode uid
    for k in $(/usr/bin/ldapsearch -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub $i amznmanageremployees | awk -F: '{ if($1 ~ /amznmanageremployees/)  print $2}' | sed 's/.*(\(.*\)).*/\1/' ); do
    /usr/bin/ldapsearch -LLL -x -h ldap.amazon.com -p 389 -b "o=amazon.com" -s sub uid=$j amznjobcode uid
  done 
done

