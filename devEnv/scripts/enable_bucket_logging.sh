#!/bin/bash

loggingBucket='ppd-s3-logs'
region='us-east-1'

                                                                                                                     # Create Logging bucket
aws --profile=ppd s3 mb s3://$loggingBucket --region $region

aws --profile=ppd s3api put-bucket-acl --bucket $loggingBucket --grant-write URI=http://acs.amazonaws.com/groups/s3/LogDelivery --grant-read-acp URI=http://acs.amazonaws.com/groups/s3/LogDelivery

# List buckets in this account
buckets="$(aws --profile ppd s3 ls | awk '{print $3}' | egrep 'ipmi|ppd|hweng')"

# Put bucket logging on each bucket
for bucket in $buckets
    do printf '{
   "LoggingEnabled": {
       "TargetBucket": "%s",
       "TargetPrefix": "%s/"
        }
    }' "$loggingBucket" "$bucket"  > logging.json
    aws --profile=ppd s3api put-bucket-logging --bucket $bucket --bucket-logging-status file://logging.json
    echo "$bucket done"
done
rm logging.json

echo "Complete"
