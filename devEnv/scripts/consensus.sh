#!/usr/bin/env python
import http
import logging
import os
import urllib.parse

import requests

COOKIE_DIR = "/Users/bsschwar/.midway"
COOKIE_FILE = os.path.join(COOKIE_DIR, "cookie")

cookie_jar = http.cookiejar.MozillaCookieJar(COOKIE_FILE)

session = requests.Session()
session.cookies = cookie_jar
MIDWAY_ENDPOINT = 'https://midway-auth.amazon.com'
session_status_url = urllib.parse.urljoin(MIDWAY_ENDPOINT, '/api/session-status')
response = session.get(session_status_url)
if not response.ok:
    logger.exception('Error while getting  session status: %s', resp_info(response))

json_response = response.json()
csrf_param = json_response['csrf_param']
csrf_token = json_response['csrf_token']
print(json_response)
