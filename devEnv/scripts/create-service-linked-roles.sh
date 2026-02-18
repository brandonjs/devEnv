#!/bin/bash -
#===============================================================================
#
#          FILE: create-service-linked-roles.sh
# 
#         USAGE: ./create-service-linked-roles.sh 
# 
#   DESCRIPTION: Create the service linked role to allow Elasticsearch to run
#                in the VPC.  This script must be run prior to deploying any 
#                new regions
# 
#       OPTIONS: ---
#  REQUIREMENTS: Admin access to the account(s) in question
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 05/10/2021 09:34:42
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error

ACCOUNT_PREFIX="aws-varia+logs"
SERVICE_ROLE="AWSServiceRoleForAmazonElasticsearchService"
REGEX="^.*-(beta|gamma|prod)-([a-z]+-([a-z]+-)?[a-z]+-[0-9]+).*$"

for template in $(ls build/cdk.out/ChozoServiceInfrastructure-*.template.json); do
  if [[ ${template} =~ ${REGEX} ]]; then
    stage="${BASH_REMATCH[1]}"
    region="${BASH_REMATCH[2]}"
    account_name="${ACCOUNT_PREFIX}+${stage}+${region}"
    aws_cli=(aws --region ${region})
    isengard=(isengard credentials --region ${region})
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    printf "Getting credentials for %s.\n" ${account_name}
    eval $(${isengard[@]} ${account_name})

    printf "Checking if %s exists.\n" ${SERVICE_ROLE}
    if [[ -z $(${aws_cli[@]} iam list-roles --output text --query 'Roles[].[RoleId,RoleName,Arn]' | grep ${SERVICE_ROLE}) ]]; then
      printf "Creating service linked role.\n"
      ${aws_cli[@]} iam create-service-linked-role --aws-service-name es.amazonaws.com
    else
      printf "Service linked role already exists.\n"
    fi
    printf "\n\n"
  fi
done
