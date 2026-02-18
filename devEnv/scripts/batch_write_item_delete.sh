#!/bin/bash -xv
#===============================================================================
#
#          FILE: batch_write_item.sh
# 
#         USAGE: ./batch_write_item.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 11/04/2024 15:48:54
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

TABLE_NAME=${1}
SEGMENT_NUMBER=${2}
TMPDIR="/tmp"
SCAN_AGGREGATE="${TMPDIR}/scan-agg-segment${SEGMENT_NUMBER}.json"
SEGMENT_FILE="${TMPDIR}/delete-segment${SEGMENT_NUMBER}.json"
MAX_ITEMS=25      # maximum number of items batch-write-item accepts
printf "starting segment - ${SEGMENT_NUMBER} \n" > ${SEGMENT_FILE}
until [[ ! -s ${SEGMENT_FILE} ]] ;
do
awk "NR>${CNT:=0} && NR<=$((CNT+MAX_ITEMS))" ${SCAN_AGGREGATE} | awk '{ print "{\"DeleteRequest\": {\"Key\": " $0 " }}," }' | sed '$ s/.$//' | sed "1 i\ 
  { \"${TABLE_NAME}\": [" | sed '$ a\ 
    ] }' > ${SEGMENT_FILE}
 
aws dynamodb batch-write-item --request-items file://${SEGMENT_FILE}
CNT=$((CNT+MAX_ITEMS))
done

