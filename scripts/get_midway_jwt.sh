#!/bin/bash - 
#===============================================================================
#
#          FILE: get_midway_jwt.sh
# 
#         USAGE: ./get_midway_jwt.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 04/27/2023 16:15:09
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

AUDIENCE=${1-"spanreed.devo.cutlass.a2z.com"}
NONCE=$(echo $RANDOM | md5sum | head -c 20; echo)

mcurl "https://midway-auth.amazon.com/SSO?response_type=id_token&client_id=${AUDIENCE}&scope=openid&nonce=${NONCE}&redirect_uri=https://${AUDIENCE}"
