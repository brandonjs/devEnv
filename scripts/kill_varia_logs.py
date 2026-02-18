#!/Users/bsschwar/.pyenv/shims/python3

import boto3
import isengard

from botocore.client import ClientError

client = isengard.Client()
accounts = {
  "752742665648": "us-east-1",
  "061855004503": "af-south-1",
  "102329798621": "ap-east-1",
  "227131358002": "ap-northeast-1",
  "780500679159": "ap-northeast-2",
  "290658457822": "ap-northeast-3",
  "644593776922": "ap-south-1",
  "073198922175": "ap-southeast-1",
  "070588778464": "ap-southeast-2",
  "679401006727": "ca-central-1",
  "834616267336": "eu-central-1",
  "728328111969": "eu-north-1",
  "766728174201": "eu-south-1",
  "426663610107": "eu-west-1",
  "879024870799": "eu-west-2",
  "702859365222": "eu-west-3",
  "161366962907": "me-south-1",
  "919839279076": "sa-east-1",
  "918755548655": "us-east-1",
  "394554806896": "us-east-2",
  "188485631731": "us-west-1",
  "633263185333": "us-west-2",
  "818568425812": "af-south-1",
  "836187631786": "ap-east-1",
  "521519734181": "ap-northeast-1",
  "247940438151": "ap-northeast-2",
  "139137360196": "ap-northeast-3",
  "322358744823": "ap-south-1",
  "490442785445": "ap-southeast-1",
  "092723523423": "ap-southeast-2",
  "051103681063": "ca-central-1",
  "316328853671": "eu-central-1",
  "520217000572": "eu-north-1",
  "877340113036": "eu-south-1",
  "429683325830": "eu-west-1",
  "140986944753": "eu-west-2",
  "240399294447": "eu-west-3",
  "000980151017": "me-south-1",
  "276370395884": "sa-east-1",
  "642711550090": "us-east-1",
  "132035491985": "us-east-2",
  "522024683613": "us-west-1",
  "677243339026": "us-west-2"
}

for account, region in accounts.items():
  session = client.get_boto3_session(account, "Admin")
  s3 = session.resource('s3')
  firehoseBucket = f'varia-firehose-logs-{account}-{region}'
  outputBucket = f'varia-security-logs-{account}-{region}'
  print(f'Running in {region}.')
  for p in ['firehose', 'security']:
    bucketName = f'varia-{p}-logs-{account}-{region}'
    try:
      print(f'Attempting to delete {p} bucket')
      s3.meta.client.head_bucket(Bucket=bucketName)
      bucket = s3.Bucket(bucketName)
      print(f'Deleting {p} bucket')
      response = bucket.object_versions.all().delete()
      bucket.delete()
    except ClientError:
      print(f'No {p} bucket found.')
