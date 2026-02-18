#!/bin/bash
function valid_aws_region() {
  [[ "$1" =~ ^(([[:lower:]]){2})-(gov-)?(iso([[:lower:]])?-)?(central|(north|south)?(east|west)?)-[[:digit:]]+$ ]]
}

email=$1
region=$2

[[ -z ${email} ]] && echo "Must provide account email" && exit 1
[[ ${email} =~ "@amazon.com" ]] || email="${email}@amazon.com"

if [[ -z ${region} ]]; then
  region=$(sed -e 's/.*+\(.*\)@amazon.com/\1/g' <<< ${email})
fi
! valid_aws_region ${region} && echo "${region} not valid, setting to us-east-1" && region="us-east-1"


eval $(isengard credentials --region ${region} --role Admin ${email})
aws --region ${region} ec2 describe-images --filters Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server*  --query 'Images[*].[ImageId,CreationDate]' --output text | sort -k2 -r | head -n1

