#!/bin/bash - 
#===============================================================================
#
#          FILE: run_batch_delete.sh
# 
#         USAGE: ./run_batch_delete.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 11/04/2024 15:49:51
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

TOTAL_SEGMENTS=100        # N, total number of segments/files exists
TABLE_NAME=${1}
for SEGMENT in `seq 0 $((${TOTAL_SEGMENTS}-1))`
do
 nohup sh ~/scripts/batch_write_item_delete.sh ${TABLE_NAME} ${SEGMENT} &
done

