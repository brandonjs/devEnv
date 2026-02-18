#!/usr/bin/env python
 
from __future__ import print_function
 
import errno
import os
import re
import subprocess
import sys
import tempfile
 
MIDWAY_PATH = os.path.expanduser('~/.midway/')
MIDWAY_KEY = os.path.join(MIDWAY_PATH, 'key')
MIDWAY_CERT = os.path.join(MIDWAY_PATH, 'public_key.crt')
 
DEVNULL = open(os.devnull, 'w')
 
def execute(cmd, env=None):
    if env:
        cmd = ['/apollo/bin/env', '-e', env] + cmd
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=DEVNULL)
    stdout = process.communicate()[0]
    if process.returncode != 0:
        raise subprocess.CalledProcessError(process.returncode, cmd)
    return stdout.decode('utf-8')
 
if __name__ == '__main__':
    with tempfile.NamedTemporaryFile(prefix='midwayexport') as cookie_file:
        curl= ['curl', '-s',
            '--negotiate', '-u', ':',
            '--header', 'x-midway-passthrough: xyzzy',
            '-A', 'Midway_CLI_Export',
            '--cookie', cookie_file.name,
            '--cookie-jar', cookie_file.name]
 
        print('Checking Kerberos status')
        kerb_status_args = ['-w', '%{http_code}', '-o', '/dev/null', 'https://kerberos.amazon.com/']
        kerb_status = int(execute(curl + kerb_status_args))
        if kerb_status != 200:
            print('Error! You must be kinited to run this script')
            sys.exit(1)
 
        print('Setting up .midway directory')
        execute(['mkdir', '-p', MIDWAY_PATH])
        execute(['rm', '-f', MIDWAY_KEY, MIDWAY_CERT])
 
        print('Requesting Midway main page')
        midway_page = execute(curl + ['https://midway.amazon.com/legacy'], env='envImprovement')
 
        print('Extracting CSRF token')
        csrf_token = re.search('name="authenticity_token" value="(.+?)"', midway_page).group(1)
 
        print('Generating private key')
        execute(['openssl', 'genrsa', '-out', MIDWAY_KEY, '2048'], env='envImprovement')
        os.chmod(MIDWAY_KEY, 0o400)
 
        print('Generating SPKAC')
        spkac_raw = execute(['openssl', 'spkac', '-key', MIDWAY_KEY], env='envImprovement')
        spkac = re.match('^SPKAC=(.*)', spkac_raw).group(1)
 
        print('Uploading SPKAC')
        generate_result = execute(curl + ['--data-urlencode', 'public_key=' + spkac,
            '--data-urlencode', 'authenticity_token=' + csrf_token,
            'https://midway.amazon.com/certificate/generate'])
        cert_id = re.search('download_cert=([0-9]+)', generate_result).group(1)
 
        print('Retrieving certificate, id #', cert_id)
        cert = execute(curl + ['https://midway.amazon.com/certificate/{0}/viewraw'.format(cert_id)])
        with open(MIDWAY_CERT, 'w') as cert_file:
            cert_file.write(cert)
 
        print('Done!')
