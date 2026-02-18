#!/bin/bash - 
#===============================================================================
#
#          FILE: purge_queue.sh
# 
#         USAGE: ./purge_queue.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 09/27/2024 13:10:31
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

email=$1
region=$(echo $1 | sed -e 's/-prod.*//g' -e 's/.*api-//g')
eval $(isengardcli credentials ${email} --region ${region} --role PasticheAdmin)
export AWS_REGION=${region}
AWS="aws --region ${region}"
queue_url=$(${AWS} sqs list-queues --queue-name-prefix PasticheTableLoaderSqsQueue-${region}-prod-DLQ | jq -r .QueueUrls[0])

echo "purging: ${queue_url}"
${AWS} sqs purge-queue --queue-url ${queue_url}

