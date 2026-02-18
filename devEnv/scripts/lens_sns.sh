#!/bin/bash


profile=$1

topic=`aws --profile=${profile} sns list-topics | grep -i tagged | awk -F\" '{print $4}'`
existing_policy="`aws --profile=$profile sns get-topic-attributes --topic-arn ${topic} | jq .[].Policy 2>&1`"
partition=`echo $topic | awk -F: '{print $2}'`
region="`echo $topic | sed -e 's/.*-//g'`"
if [ "$partition" == "aws" ]; then
   accounts="\"AWS\": [\"583964148404\", \"314416911628\", \"092307175777\", \"821031569827\"],"
elif [ "$partition" == "aws-us-gov" ]; then
   if [ "$region" == "osu" ]; then
      accounts="\"AWS\": [\"521068888385\"],"
   else
      accounts="\"AWS\": [\"519772424165\"],"
   fi
else
   accounts=""
fi

if [[ $existing_policy =~ "NoSuchPolicy" ]]; then
   existing_policy='{"Policy": "{\"Version\":\"2008-10-17\",\"Statement\":[]}"}'
   new_policy=`echo $existing_policy | jq --argjson new_pol "{\"Sid\": \"AllowCustomerSubscribe\",\"Effect\": \"Allow\",\"Principal\": { $accounts \"Service\": [\"lens.aws.internal\", \"hwmon.aws.internal\", \"${region}.lpt.hwmon.aws.internal\"],\"Action\": [ \"sns:Receive\", \"sns:Subscribe\"],\"Resource\": [\"${topic}\"]}}" '.[].Policy | fromjson | .Statement += [$new_pol]'`
else
   if [[ $existing_policy =~ "AllowCustomerSubscribe" ]]; then
      echo "Policy already exists, exiting"
      exit
   else
      new_policy=`echo $existing_policy | jq -r --argjson new_pol "{\"Sid\": \"AllowCustomerSubscribe\",\"Effect\": \"Allow\",\"Principal\": { $accounts \"Service\": [\"lens.aws.internal\", \"hwmon.aws.internal\", \"${region}.lpt.hwmon.aws.internal\"] } ,\"Action\": [ \"sns:Receive\", \"sns:Subscribe\"],\"Resource\": [\"${topic}\"]}" '. |fromjson | .Statement += [$new_pol]'`
   fi
fi
   aws --profile=${profile} sns set-topic-attributes --topic-arn ${topic} --attribute-name Policy --attribute-value "${new_policy}"

