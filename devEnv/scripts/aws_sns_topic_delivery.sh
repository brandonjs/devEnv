#!/bin/bash

airport_code="$1"
accountId=`aws --profile hwmon_${airport_code} sts get-caller-identity --output text --query 'Account'`
topicArn=`aws --profile hwmon_${airport_code} sns list-topics | grep -i hwmon-sqs-message-tagged | awk -F\" '{print $4}'`
successRole=`aws --profile hwmon_${airport_code} iam list-roles |grep "role/SNSSuccessFeedback" | awk -F\" '{print $4}'`
failureRole=`aws --profile hwmon_${airport_code} iam list-roles |grep "role/SNSFailureFeedback" | awk -F\" '{print $4}'`

[ -z $topicArn ] && echo "topicArn not found, exiting." && exit
[ -z $accountId ] && echo "accountId not found, exiting." && exit

sampleRate="100"

# Create roles:
for attribute in LambdaFailureFeedbackRoleArn HTTPFailureFeedbackRoleArn SQSFailureFeedbackRoleArn ApplicationFailureFeedbackRoleArn; do
   aws --profile hwmon_${airport_code} sns set-topic-attributes --topic-arn ${topicArn} --attribute-name ${attribute} --attribute-value ${failureRole}
done

for attribute in ApplicationSuccessFeedbackRoleArn LambdaSuccessFeedbackRoleArn HTTPSuccessFeedbackRoleArn SQSSuccessFeedbackRoleArn; do
   aws --profile hwmon_${airport_code} sns set-topic-attributes --topic-arn ${topicArn} --attribute-name ${attribute} --attribute-value ${successRole}

done

for attribute in HTTPSuccessFeedbackSampleRate LambdaSuccessFeedbackSampleRate SQSSuccessFeedbackSampleRate ApplicationSuccessFeedbackSampleRate; do
   aws --profile hwmon_${airport_code} sns set-topic-attributes --topic-arn ${topicArn} --attribute-name ${attribute} --attribute-value ${sampleRate}

done

