#!/bin/bash - 
#===============================================================================
#
#          FILE: create-hostclass.sh
# 
#         USAGE: ./create-hostclass.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 12/01/2021 13:23:43
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
echo "creating host class"
echo "Parent hostclass is "  $2
echo "Hostclass to be created "  $1

mcurl -H "X-CSRF-Token: $(mcurl -sk https://provisioning-web.amazon.com/csrf-token)" -X POST  "https://provisioning-web.amazon.com/hostclasses?name=$1&parent_hostclass=$2"

echo "completed"

