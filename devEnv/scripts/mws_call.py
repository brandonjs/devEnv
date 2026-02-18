#!/Users/bsschwar/.pyenv/shims/python3

import datetime
from aws_requests_auth.aws_auth import AWSRequestsAuth as sigv4_auth
from datetime import datetime as date
import time
import hmac
import hashlib
import os
import requests
import urllib
import urllib.parse
from base64 import b64encode
from hashlib import sha1

HOST = 'monitor-api.amazon.com'
ENDPOINT = f'http://{HOST}'

ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
TOKEN = os.environ.get('AWS_SESSION_TOKEN')

alarm_name='us-west-2:Turtle_Credentials_Failed'
mws_params = {
    'Action': 'PutAlarmsStateForAggregation',
    'name': alarm_name,
    'entity': 'pmet',
    'source': 'performance alarm monitor',
    'Version': '2007-07-07'
}

auth = sigv4_auth(
    aws_region = 'us-east-1',
    aws_service = 'monitor-api',
    aws_host = HOST,
    aws_access_key = ACCESS_KEY_ID,
    aws_secret_access_key = SECRET_KEY,
    aws_token = TOKEN)

resp = requests.request(
    'GET',
    ENDPOINT,
    params=mws_params or None,
    data=None,
    headers=None,
    auth=auth
 )
print(resp.content)
