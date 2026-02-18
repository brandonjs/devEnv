#!/usr/local/bin/bash
STAGE=prod
regions=(af-south-1 ap-east-1 ap-northeast-1 ap-northeast-2 ap-northeast-3 ap-south-1 ap-south-2 ap-southeast-1 ap-southeast-2 ap-southeast-3 ap-southeast-4 ca-central-1 cn-north-1 cn-northwest-1 eu-central-1 eu-central-2 eu-north-1 eu-south-1 eu-south-2 eu-west-1 eu-west-2 eu-west-3 me-central-1 me-south-1 me-west-1 sa-east-1 us-east-1 us-east-2 us-gov-east-1 us-gov-west-1 us-west-1 us-west-2)
for region in ${regions[@]}; do
  echo "REGION: ${region}"
  export AWS_DEFAULT_REGION=${region}
  ec=0
  creds=$(isengard credentials --region ${region} --role Admin aws-varia+logs+${STAGE}+${region}@amazon.com 2>/dev/null) || ec=$?
  if [[ ${ec} -ne 0 ]]; then
    echo "No creds."
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    continue
  else
    eval ${creds}
  fi
  [[ -z ${AWS_ACCESS_KEY_ID} ]] && continue
  accountId=$(aws sts get-caller-identity | jq -r .Account)
  stack_details=$(aws cloudformation describe-stacks --stack-name VariaLogsInfrastructure-${STAGE}-${region} 2>&1)
  if ! [[ ${stack_details} =~ "does not exist" ]]; then
    aws cloudformation update-termination-protection --no-enable-termination-protection --stack-name VariaLogsInfrastructure-${STAGE}-${region}
    aws cloudformation delete-stack --stack-name VariaLogsInfrastructure-${STAGE}-${region}
  fi
  bucket="varia-firehose-logs-${accountId}-${region}"
  aws s3api head-bucket --bucket ${bucket} 2>/dev/null
  if [[ $? -eq 0 ]]; then
    lifecycle=$(aws s3api get-bucket-lifecycle-configuration --bucket ${bucket})
    if ! [[ ${lifecycle} =~ "Kill it with fire" ]]; then
      echo "Putting lifecycle rule"
      aws s3api put-bucket-lifecycle-configuration --bucket ${bucket} --lifecycle-configuration  file://lifecycle.json
    fi
  fi
  buckets=(varia-security-logs-${accountId}-${region} varia-firehose-logs-${accountId}-${region})
  for bucket in ${buckets[@]}; do
    aws s3api head-bucket --bucket ${bucket} 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo "Deleting: ${bucket}"
      aws s3api delete-objects --bucket ${bucket} --delete "$(aws s3api list-object-versions --bucket ${bucket} --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"
      aws s3api delete-objects --bucket ${bucket} --delete "$(aws s3api list-object-versions --bucket ${bucket} --query='{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}')"
      aws s3 rb --force s3://${bucket}
    fi
  done
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_DEFAULT_REGION
done


