#!/bin/bash -
#===============================================================================
#
#          FILE: delete_all_dynamodb_items.sh
# 
#         USAGE: ./delete_all_dynamodb_items.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 09/28/2021 07:19:56
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

ACCOUNT_PREFIX="aws-varia+canary"
TABLE_PREFIX="ChozoCanaryHydra"
REGEX="^.*-(beta|gamma|prod)-([a-z]+-([a-z]+-)?[a-z]+-[0-9]+).*$"
#RIPCLI="ssh bsschwar-desk.aka.amazon.com ripcli"
#REGIONS=$(${RIPCLI} regions | awk '{print $NF}' | egrep -v "(us|eu)-iso")
STAGE="prod"
REGIONS=(ap-northeast-3)
for region in ${REGIONS[@]}; do
  account_name="${ACCOUNT_PREFIX}+${STAGE}+${region}"
  aws_cli=(aws --region ${region})
  isengard=(isengard credentials --region ${region})
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  printf "Getting credentials for %s.\n" ${account_name}
  eval $(${isengard[@]} ${account_name})
  [[ "x${AWS_ACCESS_KEY_ID}" == "x" ]] && echo "no creds, moving on." && continue

  tableName=$(${aws_cli[@]} dynamodb list-tables | jq -r '.TableNames[] | tostring | select(contains("'${TABLE_PREFIX}'"))')
  printf "Table name: %s.\n" ${tableName}
  hashKey=$(${aws_cli[@]} dynamodb describe-table --table-name $tableName | jq -r '.Table.KeySchema[] | select(.KeyType=="HASH") | .AttributeName')
  printf "Hash key: %s.\n" ${hashKey}

  echo "deleting table items."
  ${aws_cli[@]} dynamodb scan --attributes-to-get $hashKey --table-name $tableName --query "Items[*]" | jq --compact-output '.[]' | tr '\n' '\0' | xargs -0 -t -I keyItem ${aws_cli[@]} dynamodb delete-item --table-name $tableName --key=keyItem
done
