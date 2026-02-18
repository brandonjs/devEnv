#!/usr/bin/python

import sys;
import threading

import urllib
import boto3
import ast
import json
import uuid
import re
import os
import argparse
import subprocess
from hashlib import md5;
from sys import argv
from base64 import b64decode
from multiprocessing import Pool
from hwmon_common.creds import get_credential_pair
from botocore.errorfactory import ClientError

region = sys.argv[0]
if not region:
   print "Must specify a region"
   exit()

migration_host = "hwmon-data-migration.c3s0peiyhupu.us-east-1.rds.amazonaws.com"
migration_db_creds = com.amazon.hwmon-ws.MigrationDBCreds.rw
#aws --profile=sqs_server_s3_ro s3 sync  s3://hwmon-storage-global/b6b51e356b829f3c s3://hwmon-storage-cmh/b6b51e356b829f3c

source_s3_bucket = "hwmon-storage-global"
source_s3_region = "us-east-1"
source_s3_material_set = "com.amazon.hwmon.accounts.hwmon-sqs-server.hwmon-s3.ro"
source_access_key, source_secret_key = get_credential_pair(source_s3_material_set)

s3 = boto3.client('s3',
       region_name='us-east-1',
       aws_access_key_id=source_access_key,
       aws_secret_access_key=source_secret_key)


print md5(sys.argv[1:][0]).hexdigest()[:16]

def worker():
   run(["aws", "s3", "sync", "--quiet", "s3://hwmon-storage-global/", "s3://hwmon-storage-region/"])


def run(cmd):
    p = subprocess.Popen(cmd)
    return p.wait()

