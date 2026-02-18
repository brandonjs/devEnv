#!/bin/bash -xv

REGIONS="ap-east-1 ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-north-1 eu-south-1 eu-west-1 eu-west-2 eu-west-3 me-south-1 sa-east-1 us-east-1 us-east-2 us-west-1 us-west-2"

for region in ${REGIONS}; do
    EMAIL="aws-varia+logs+prod+${region}@amazon.com"
    isengard grant ${EMAIL} ${USER}
    eval `isengard credentials ${EMAIL}`
    for stack in `aws --region ${region} cloudformation list-stacks | jq -r .StackSummaries[].StackName`; do
        aws --region ${region} cloudformation update-termination-protection --stack-name ${stack} --enable-termination-protection
    done
    isengard revoke ${EMAIL} `whoami`
done
