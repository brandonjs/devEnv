#!/Users/bsschwar/.pyenv/versions/3.6.8/bin/python

import amazoncerts
import isengard
import json
import re
import datetime
import os
import sys
import subprocess
from shutil import copyfile

accounts = {}
client = isengard.Client().client
accounts['classic'] = client.get_permissions_for_user().get('PermissionsForUserList')
client = isengard.Client(region='cn-north-1').client
accounts['cn'] = client.get_permissions_for_user().get('PermissionsForUserList')
client = isengard.Client(region='us-gov-west-1').client
accounts['itar'] = client.get_permissions_for_user().get('PermissionsForUserList')
accounts['classic'] = sorted(accounts['classic'], key=lambda item: item.get('AWSAccountMoniker').get('Name'))
accounts['cn'] = sorted(accounts['cn'], key=lambda item: item.get('AWSAccountMoniker').get('Name'))
accounts['itar'] = sorted(accounts['itar'], key=lambda item: item.get('AWSAccountMoniker').get('Name'))
fname = "/Users/bsschwar/.aws/config"
fname_backup = "/Users/bsschwar/.aws/backup/config.{}".format(datetime.datetime.now().strftime("%s"))
template = "/Users/bsschwar/.aws/config_template"

default_regions = { 'classic': 'us-east-1', 'itar': 'us-gov-west-1', 'cn': 'cn-north-1' }

copyfile(fname, fname_backup)
print("~/.aws/config saved to: {}".format(fname_backup))

copyfile(template, fname)

def get_role(roles):
    if roles:
        roles_lower = map(str.lower, roles)
        try:
            return roles[roles_lower.index('admin')]
        except:
            try:
                return roles[roles_lower.index('readonly')]
            except:
                return roles[0]
    else:
        return "Can't decide role"

def get_region(name, partition):
    result = re.match(r'.*\+([a-z]{2}-[a-z]{3}?-?[a-z]*-[0-9])@.*', name)
    if result:
        region = result.groups()[0]
    else:
        region = default_regions.get(partition)

    return region

def shorten_name(name, partition):
    result = re.match(r'.*\+([a-z]{2}-[a-z]{3}?-?[a-z]*-[0-9])@.*', name)
    name = name.replace('@amazon.com', '')
    name = name.replace('aws-safety-infrastructure', 'asi')
    name = name.replace('aws-barrister', 'bar')
    name = name.replace('+', '_').replace('-', '_')

    if not result and partition != 'classic':
        name = f"{name}_{partition}"

    return name

with open(fname, "a") as f:
    f.write("\n")

for partition, accounts in accounts.items():
    for acc in accounts:
        account = acc.get('AWSAccountMoniker')
        email = account.get('Email')
        if email == "lpt-cli@amazon.com":
            continue
        if re.match('aws-varia-service', email):
            continue

        region = get_region(email, partition)
        name = shorten_name(email, partition)
        account_id = account.get('AWSAccountID')
        roles = acc.get('IAMRoleNameList')
        role = get_role(roles)
#        f.write(f"[profile {name}]\nregion = {region}\naccount = {account_id}\nrole = {role}\n\n")
        if partition != 'classic':
          isen_region = default_regions.get(partition)
          entry = f'[profile {name}]\ncredential_process = isengard credentials --awscli {email} --role {role} --region {isen_region}\nregion = {region}\n\n'
        else:
          entry = f'[profile {name}]\ncredential_process = isengard credentials --awscli {email} --role {role}\nregion = {region}\n\n'
        with open(fname, "a") as f:
            f.write(entry)
