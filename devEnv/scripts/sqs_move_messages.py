#!/usr/local/bin/python2.7

import boto3
import sys
import Queue
import threading

work_queue = Queue.Queue()
region = sys.argv[4]
region_2 = region
if len(sys.argv) > 5:
   region_2 = sys.argv[5]
session = boto3.Session(profile_name = sys.argv[3], region_name = region)
sqs = session.client('sqs')
session = boto3.Session(profile_name = sys.argv[3], region_name = region_2)
sqs2 = session.client('sqs')

from_q_name = sys.argv[1]
to_q_name = sys.argv[2]
print("From: " + from_q_name + " To: " + to_q_name)

print(from_q_name)
from_q = sqs.get_queue_url(QueueName=from_q_name)['QueueUrl']
print(from_q)
print(to_q_name)
to_q = sqs2.get_queue_url(QueueName=to_q_name)['QueueUrl']
print(to_q)

def process_queue():
    while True:
         messages = work_queue.get()

         bodies = list()
         delete = list()
         for i in range(0, len(messages)):
            msg_id = messages[i]['MessageId']
            msg_body = messages[i]['Body']
            rh = messages[i]['ReceiptHandle']
            bodies.append({'Id': msg_id, 'MessageBody': msg_body})
            delete.append({'Id': messages[i]['MessageId'], 'ReceiptHandle': messages[i]['ReceiptHandle']})

         sqs2.send_message_batch(QueueUrl=to_q, Entries=bodies)

         print("Copied %d messages" % len(messages))
         sqs.delete_message_batch(QueueUrl=from_q, Entries=delete)

for i in range(10):
     t = threading.Thread(target=process_queue)
     t.daemon = True
     t.start()

while True:
   messages = list()
   response = sqs.receive_message(
            QueueUrl=from_q,
            MaxNumberOfMessages=10,
            VisibilityTimeout=123,
            WaitTimeSeconds=20,
            AttributeNames=['All'],
            MessageAttributeNames=['All'])
#print response['Messages'][0]['ReceiptHandle']
#exit()
   messages.extend(response['Messages'])
   work_queue.put(messages)
