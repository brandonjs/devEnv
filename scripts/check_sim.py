#!/Users/bsschwar/.pyenv/shims/python

import boto3
import os


SIM_ROLE=""
SIM_ROLE_SESSION="bsschwar"

sts_client = boto3.client(
    'sts',
    aws_access_key=os.environ.get('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.environ.get('AWS_SECRET_ACCESS_KEY'),
    aws_session_token=os.environ.get('AWS_SESSION_TOKEN')
)

temp_credentials = sts_client.assume_role(
    RoleArn=SIM_ROLE,
    RoleSessionName=SIM_ROLE_SESSION
)

auth = AWSRequestsAuth(aws_access_key=temp_credentials['Credentials']['AccessKeyId'],
                       aws_secret_access_key=temp_credentials['Credentials']['SecretAccessKey'],
                       aws_host='issues-ext.amazon.com',
                       aws_token=temp_credentials['Credentials']['SessionToken'],
                       aws_region='us-east-1',
                       aws_service='sim')

response = requests.get(f'https://issues-ext.amazon.com/issues/{issue}')

print(response.content)
return response
