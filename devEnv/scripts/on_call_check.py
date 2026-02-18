#!/Library/Frameworks/Python.framework/Versions/3.6/bin/python3

import pprint
import isengard
import json
import amazoncerts
import boto3
import requests
from requests_aws4auth import AWS4Auth

client = isengard.Client()
account = {'AWSAccountID': '971593487406', 'AWSAccountMoniker': {'AWSAccountID': '971593487406', 'Email': 'bsschwar@amazon.com', 'Name': 'bsschwar@amazon.com', 'Group': 'IndividualDevAccounts', 'Status': 'ACTIVE', 'BaselineNeeded': True, 'MarkedProduction': False}, 'IAMRoleNameList': ['Admin', 'SecondRestRole', 'TestRole1']}
account_id = account.get('AWSAccountID')
role = 'Admin'
credentials = client.get_assume_role_credentials(account_id, role)
access_key = credentials.get('aws_access_key_id')
secret_key = credentials.get('aws_secret_access_key')
token = credentials.get('security_token')

host = "who-is-oncall-pdx.corp.amazon.com"
service_name = "who-is-oncall"
aws_region = 'us-west-2'

headers = {'content-type': 'application/json', 'host': host}
auth = AWS4Auth(access_key, secret_key, aws_region, service_name, session_token=token)
team_name = "aft-ind-cmbr"

#r = requests.get("https://{}/teams/{}".format(host, team_name), headers=headers, auth=auth)
results = []

res = requests.get("https://{}/aliases".format(host), headers=headers, auth=auth)
raw = res.json()

# True
#res.ok
for i in raw:
    results.append(i)

#print(res.links['next'])
while res.links.get('next') != None:
    res = requests.get("https://{}{}".format(host, res.links.get('next').get('url')), headers=headers, auth=auth)
    raw = res.json()
    for i in raw:
        results.append(i)

f = open("/tmp/results", "w")
f.write(json.dumps(results))
f.close()
#print(results)
#if js.get('alias'):
#  print(js.get('alias'))
#for item in js:
#    pprint.pprint(item)
#    if item.get('teamName') == team_name:
#        pprint.pprint(item)
