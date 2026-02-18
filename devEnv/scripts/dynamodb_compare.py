#!/Library/Frameworks/Python.framework/Versions/3.6/bin/python3
import isengard
import amazoncerts
import json
import os
import boto3
import hashlib
from collections import OrderedDict

table_name = 'BlackGreyDayRules'
client = isengard.Client()
source = client.get_boto3_session("807976052971", "Admin", region="us-east-1")
dest = client.get_boto3_session("807976052971", "Admin", region="us-west-2")
source_ddb = source.client('dynamodb')
dest_ddb = dest.client('dynamodb')

def hash_table(table_name, ddb):
    response = ddb.scan(TableName = table_name, ConsistentRead=True)
    data = response['Items']
    while 'LastEvaluatedKey' in response:
        response = ddb.scan(TableName = table_name, ConsistentRead=True, ExclusiveStartKey=response['LastEvaluatedKey'])
        data.extend(response['Items'])
    sorted_data = [OrderedDict(sorted(x.items(), key=lambda t: t[0])) for x in data]
    data_str = json.dumps(sorted_data).encode()
    return hashlib.sha256(data_str).hexdigest(), data_str

source_hash, _ = hash_table(table_name, source_ddb)
dest_hash, _ = hash_table(table_name, dest_ddb)

print(source_hash)
print(dest_hash)
