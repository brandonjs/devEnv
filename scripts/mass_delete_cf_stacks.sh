#!/usr/local/bin/bash -
#set -o nounset                              # Treat unset variables as an error

[[ -z $1 ]] && echo "Must specify stack prefix to delete." && exit 1
ACCOUNT_PREFIX="aws-varia+logs"
STACK_PREFIX=$1
#REGEX="^.*-(beta|gamma|prod)-([a-z]+-([a-z]+-)?[a-z]+-[0-9]+).*$"
RIPCLI="ssh bsschwar-desk.aka.amazon.com ripcli"
REGIONS=$(${RIPCLI} regions | awk '{print $NF}' | egrep -v "(us|eu)-iso")
#REGIONS=(af-south-1)
STAGE="prod"
for region in ${REGIONS[@]}; do
  account_name="${ACCOUNT_PREFIX}+${STAGE}+${region}"
  aws_cli=(aws --region ${region})
  isengard=(isengard credentials --region ${region})
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  printf "Getting credentials for %s.\n" ${account_name}
  eval $(${isengard[@]} ${account_name} | grep export)
  [[ "x${AWS_ACCESS_KEY_ID}" == "x" ]] && echo "no creds, moving on." && continue

  stackName=$(${aws_cli[@]} cloudformation list-stacks | jq -r '.StackSummaries[] | select(.StackName|test("'${STACK_PREFIX}'")) | select(.StackStatus|test("DELETE")|not) | .StackName')

  [[ "x${stackName}" == "x" ]] && echo "Stack with prefix ${STACK_PREFIX} doesn't exist.  Moving on to next region." && continue
  printf "Stack name: %s.\n" ${stackName}

  echo "disabling termination protection."
  ${aws_cli[@]} cloudformation update-termination-protection --no-enable-termination-protection --stack-name ${stackName}

  echo "deleting stack."
  ${aws_cli[@]} cloudformation delete-stack --stack-name ${stackName}

  echo "deleting log groups."
  ${aws_cli[@]} logs delete-log-group --log-group-name SinglePassBastion-AppContainer-STDOUT
  ${aws_cli[@]} logs delete-log-group --log-group-name SinglePassBastion-FireLensContainerLogs
  ${aws_cli[@]} logs delete-log-group --log-group-name SinglePassBastion-SinglePassSyncLogs
done
