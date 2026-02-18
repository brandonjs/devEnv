#!/usr/bin/env python
import isengard
import boto3
import sys
import os

if len(sys.argv) < 3:
  print("Usage: %s <source_table_name> <destination_table_name> <source_account_id> <dest_account_id>"% sys.argv[0])
  sys.exit(1)

src_table = sys.argv[1]
dst_table = sys.argv[2]
source_account = sys.argv[3]
try:
  dest_account = sys.argv[4]
except IndexError:
  dest_account = source_account

region = os.getenv('SOURCE_REGION', 'us-west-2')
print(f"Using source_region: {region}")
dest_region = region

if dest_account: 
  dest_region = os.getenv('DEST_REGION', 'us-west-2')

print(f"Using dest_region: {dest_region}")
batch_size = 25

def migrate(source, target):
  is_client = isengard.Client()

  is_boto_sess = is_client.get_boto3_session(source_account, "Admin")
  source_dynamo_client = is_boto_sess.client(service_name='dynamodb', region_name=region)
  source_tables = source_dynamo_client.list_tables()['TableNames']
  if src_table not in source_tables:
      print(f"Table: {src_table} does not exist in account: {source_account} and region: {region}")
      return

  dest_boto_sess = is_client.get_boto3_session(dest_account, "Admin")
  dest_dynamo_client = dest_boto_sess.client(service_name='dynamodb', region_name=dest_region)
  dest_tables = dest_dynamo_client.list_tables()['TableNames']
  if dst_table not in dest_tables:
      print(f"Table: {dst_table} does not exist in account: {dest_account} and region: {dest_region}")
      return

  dynamo_paginator = source_dynamo_client.get_paginator('scan')
  dynamo_response = dynamo_paginator.paginate(
    TableName=source,
    Select='ALL_ATTRIBUTES',
    ReturnConsumedCapacity='NONE',
    ConsistentRead=True
  )
  page_count = 1
  for page in dynamo_response:
    total_items = page['Items']
    print(f"Loading page {page_count} with items: {len(total_items)}")
    page_count += 1
    unprocessed_items = []
    while len(total_items) > 0:
      items_to_send = total_items[:batch_size]
      total_items = total_items[batch_size:]
      print(f"Batch_writing {batch_size} items to table: {target}. Remaining: {len(total_items)}")
      response = dest_dynamo_client.batch_write_item(
        RequestItems={
          target: [{'PutRequest': {'Item': item }} for item in items_to_send]
        }
      )
      unprocessed_items = response['UnprocessedItems']
      if unprocessed_items and unprocessed_items[target]:
        total_items.extend(unprocessed_items[target])
      

if __name__ == '__main__':
  if src_table == dst_table and source_account == dest_account and region == dest_region:
    raise Exception("Cannot duplicate table to itself!!!")

  migrate(src_table, dst_table)
