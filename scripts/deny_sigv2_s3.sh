#!/bin/bash

profile=$1
if [[ $profile =~ "bjs" ]] || [[ $profile =~ "zhy" ]]; then
   arn="arn:aws-cn:s3::"
elif [[ $profile =~ "osu" ]] || [[ $profile =~ "pdt" ]]; then
   arn="arn:aws-us-gov:s3::"
else
   arn="arn:aws:s3::"
fi

for bucket in `aws --profile=$profile s3api list-buckets | jq -r '.Buckets[] | .Name' | egrep -v "do-not-delete|lpt"`; do
   echo $bucket
   BUCKET=$bucket
   ARN=$arn
   existing_policy="`aws --profile=$profile s3api get-bucket-policy --bucket $bucket 2>&1`"
   if [[ $existing_policy =~ "NoSuchBucketPolicy" ]]; then
      existing_policy='{"Policy": "{\"Version\":\"2008-10-17\",\"Id\":\"S3Access\",\"Statement\":[]}"}'
      new_policy=`echo $existing_policy | jq --arg BUCKET $bucket --argjson new_pol "{\"Sid\": \"DisableSigV2\",\"Effect\": \"Deny\",\"Principal\": \"*\",\"Action\": \"s3:*\",\"Resource\": [\"$ARN:$BUCKET/*\",\"$ARN:$BUCKET\"],\"Condition\": {\"StringEquals\": {\"s3:signatureversion\": \"AWS\"}}}" '.Policy | fromjson | .Statement += [$new_pol]'`
   else
      if [[ $existing_policy =~ "DisableSigV2" ]]; then
         continue
      else
         new_policy=`echo $existing_policy | jq --arg BUCKET $bucket --argjson new_pol "{\"Sid\": \"DisableSigV2\",\"Effect\": \"Deny\",\"Principal\": \"*\",\"Action\": \"s3:*\",\"Resource\": [\"$ARN:$BUCKET/*\",\"$ARN:$BUCKET\"],\"Condition\": {\"StringEquals\": {\"s3:signatureversion\": \"AWS\"}}}" '.Policy | fromjson | .Statement += [$new_pol]'`
      fi
   fi
   echo aws --profile=$profile s3api put-bucket-policy --bucket $bucket --policy "${new_policy}"
done

