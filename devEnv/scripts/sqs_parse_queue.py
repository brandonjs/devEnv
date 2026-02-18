#!/usr/local/bin/python2.7

import boto3
import re
import sys
import Queue
import threading

work_queue = Queue.Queue()
session = boto3.Session(profile_name = sys.argv[2], region_name = 'us-east-1')
sqs = session.client('sqs')

from_q_name = sys.argv[1]

from_q = sqs.get_queue_url(QueueName=from_q_name)['QueueUrl']

def process_queue():
    while True:
         messages = work_queue.get()

         bodies = list()
         delete = list()
         for i in range(0, len(messages)):
            msg_id = messages[i]['MessageId']
            msg_body = messages[i]['Body']
            rh = messages[i]['ReceiptHandle']
            if re.match("Confirm", msg_body):
               print(msg_body)


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
