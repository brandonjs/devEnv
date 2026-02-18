#!/usr/bin/env python3

import boto3
import os

from botocore.exceptions import ClientError

table_name = 'DataStore'
params = { 
    'TableName': table_name,
    'FilterExpression': 'contains(#list, :map_val)',
    'ExpressionAttributeNames': {'#list': 'destinations'},
    'ExpressionAttributeValues': {':map_val': {'M': {'name': {'S': 'aws-iso-b'}}}}
}

#dynamodb = boto3.resource("dynamodb", region_name = os.getenv("AWS_REGION"))
client = boto3.client("dynamodb", region_name = os.getenv("AWS_REGION"))
#table = dynamodb.Table(table_name)

all_items = []
last_evaluated_key = None

def scan_table_with_pagination(table_name):
    while True:
        response = client.scan(**params)

        yield response.get('Items', [])

        if 'LastEvaluatedKey' not in response:
            break

        params['ExclusiveStartKey'] = response['LastEvaluatedKey']

item_count = 0

for page in scan_table_with_pagination(table_name):
    item_count += len(page)
    # Process each page of items
#    all_items.extend(page)
    all_items.extend([x["recordId"]["S"] for x in page])
#    for item in page:
#        print(item)

print(f"Total number of items found: {item_count}")
print(all_items)

#while True:
#    try:
#        if last_evaluated_key:
#            response = table.scan(**params, ExclusiveStartKey=last_evaluated_key)
#        else:
#            response = table.scan(**params)

#        if 'Items' in response:
#            all_items.extend(response['Items'])
        
#        if 'LastEvaluatedKey' in response:
#            last_evaluated_key = response['LastEvaluatedKey']
#        else:
#            last_evaluated_key = None  # Signal that there are no more pages
#            break  # Exit the loop

#    except ClientError as e:
#        print(f"Error during scan: {e}")
#        break

#    print(f"Total items scanned: {len(all_items)}")
