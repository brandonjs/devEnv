#!/bin/bash - 
#===============================================================================
#
#          FILE: scan_dynamo_table.sh
# 
#         USAGE: ./scan_dynamo_table.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 11/04/2024 15:55:51
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

TABLE_NAME=$1
TOTAL_SEGMENTS=$2
SEGMENT_NUMBER=$3
TMPDIR="/tmp"
MAX_ITEMS=4200
SCAN_OUTPUT="${TMPDIR}/scan-output-segment${SEGMENT_NUMBER}.json"
SCAN_AGGREGATE="${TMPDIR}/scan-agg-segment${SEGMENT_NUMBER}.json"
aws dynamodb scan --table-name "${TABLE_NAME}" --max-items ${MAX_ITEMS} --total-segments ${TOTAL_SEGMENTS} --projection-expression "id" --segment ${SEGMENT_NUMBER} > ${SCAN_OUTPUT}
NEXT_TOKEN="$(cat ${SCAN_OUTPUT} | jq '.NextToken')"
cat ${SCAN_OUTPUT} | jq -r ".Items[] | tojson" > ${SCAN_AGGREGATE}
while [ ! -z "$NEXT_TOKEN" ] && [ ! "$NEXT_TOKEN" == null ]
do
aws dynamodb scan --table-name "${TABLE_NAME}" --max-items ${MAX_ITEMS} --total-segments ${TOTAL_SEGMENTS} --projection-expression "id" --segment ${SEGMENT_NUMBER} --starting-token ${NEXT_TOKEN} > ${SCAN_OUTPUT}

NEXT_TOKEN="$(cat ${SCAN_OUTPUT} | jq '.NextToken')"
cat ${SCAN_OUTPUT} | jq -r ".Items[] | tojson" >> ${SCAN_AGGREGATE}
done

