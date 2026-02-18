#!/bin/bash - 
#===============================================================================
#
#          FILE: fix_api_gateway_output.sh
# 
#         USAGE: ./fix_api_gateway_output.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Brandon Schwartz (), bsschwar@amazon.com
#  ORGANIZATION: AWS Safety Infrastructure
#       CREATED: 06/11/2021 08:36:55
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


REGION="af-south-1"
REGIONS="ap-east-1 ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-north-1 eu-south-1 eu-west-1 eu-west-2 eu-west-3 me-south-1 sa-east-1 us-east-1 us-east-2 us-west-1 us-west-2"
REGIONS="cn-north-1 cn-northwest-1"
for region in ${REGIONS}; do
  eval `isengard credentials --region ${region} aws-varia+logs+gamma+${region}@amazon.com`
  STACK_NAME="ChozoServiceApiGateway-gamma-${region}"
  OUTPUT_INFO=$(aws --region ${region} cloudformation list-exports | jq '.Exports[] | select(.Name|test("ExportsOutputRefServiceLB"))')
  EXPORT=$(jq -r .Name <<< ${OUTPUT_INFO})
  VALUE=$(jq -r .Value <<< ${OUTPUT_INFO})
  OUTPUT_FILE="cf_output_file.json"
  OUTPUT_PATH="/tmp/${OUTPUT_FILE}"
  BUCKET=$(aws --region ${region} s3api list-buckets | jq -r '[.Buckets[] | select(.Name|test("deploymentbucket")) | .Name] | first')
  BUCKET_PATH="${BUCKET}/${OUTPUT_FILE}"
  aws --region ${region} cloudformation get-template --stack-name ${STACK_NAME} | jq '.TemplateBody' > ${OUTPUT_PATH}
  perl -0777  -pi.bak -e 's|(\"TargetArns\": \[).*?(\])|${1} "'${VALUE}'" ${2}|s' ${OUTPUT_PATH}
  aws --region ${region} s3 cp ${OUTPUT_PATH} s3://${BUCKET_PATH}
  aws --region ${region} cloudformation update-stack --capabilities CAPABILITY_IAM --stack-name ${STACK_NAME} --template-url https://s3.${region}.amazonaws.com.cn/${BUCKET_PATH}
  aws --region ${region} s3 rm s3://${BUCKET_PATH}
done
