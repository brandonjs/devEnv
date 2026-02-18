#!/bin/bash - 
#===============================================================================
#
#          FILE: run_scan_table.sh
# 
#         USAGE: ./run_scan_table.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 11/04/2024 16:01:10
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

TABLE_NAME=${1}
TOTAL_SEGMENTS=100          # N, total number of segments
for SEGMENT in `seq 0 $((${TOTAL_SEGMENTS}-1))`
do
 nohup sh ~/scripts/scan_dynamo_table.sh ${TABLE_NAME} ${TOTAL_SEGMENTS} ${SEGMENT} &
done

