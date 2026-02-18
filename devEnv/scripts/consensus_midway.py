import amazoncerts
import os
import tempfile

from requests import Session
from time import time

from http.cookiejar import Cookie, MozillaCookieJar

MIDWAY_COOKIE_PATH = os.path.expanduser('~/.midway/cookie')
API_URL = 'https://api.consensus.a2z.com'


class MidwayException(Exception):
    pass


class Consensus: 

  def __init__(self, service_name):
    self.service_name = service_name
    self.session = Session()
    self.session.cookies = self.get_cookie_jar()
    self.session.get(API_URL+'/v2/getUserInfo')

    self.csrf = None
    for cookie in self.session.cookies:
     if cookie.name == 'CSRF-TOKEN':
       self.csrf = cookie.value
       break

  def get_cookie_jar(self, cookie_file=MIDWAY_COOKIE_PATH):
    if not os.path.isfile(cookie_file):
      raise MidwayException(
        "File '{}' does not exist. Could not find your Midway Cookie.".format(cookie_file))

    tmp_file = tempfile.NamedTemporaryFile()
    # Cheating: just remove HttpOnly_ flag.
    # If created on Windows, cookie value will have \r at the end on Linux,
    # which breaks SSL connection with midway-auth
    tmp_file.write(("".join([line.strip("\r").replace("#HttpOnly_", "").replace("^.", "") for line in open(cookie_file, "r").readlines()])).encode('utf-8'))
    tmp_file.flush()

    ns_cookiejar = MozillaCookieJar()
    ns_cookiejar_tmp = MozillaCookieJar()
    ns_cookiejar_tmp.load(tmp_file.name, ignore_discard=True, ignore_expires=True)
    cookies_were_set = False

    # Processes all cookies to find multiple valid cookies (e.g. itar and global)
    for c in ns_cookiejar_tmp:
      args = dict(vars(c).items())
      args['rest'] = args['_rest']
      del args['_rest']
      c = Cookie(**args)

#      try:
#        ns_cookiejar.clear(c.domain)
#      except KeyError:
#        pass

      if not c.domain.startswith("midway-auth") and not c.domain.startswith(".midway-auth"):
        # There might be other cookies in the file, and the only one we actually need is for
        # 'midway-auth'
        continue
      if c.expires > 0 and c.expires < int(time()):
        continue
      if c.expires == 0:
        c.expires = None  # convert curl format to python cookie format
      ns_cookiejar.set_cookie(c)
      cookies_were_set = True

    if not cookies_were_set:
      # We did not encounter a break, so we did not find a valid cookie.
      raise MidwayException("Did not find a valid Midway Cookie. Please run 'mwinit'")

    return ns_cookiejar
  
  
  def create_user_review_request(self, action: str, long_description: str):
    data = {
      "action": f"{action}",
      "service": self.service_name,
      "longDescription": long_description,
      "ruleOperator": "AND",
      "rules": [
        {
          "type": "Ldap",
          "name": "aws-varia",
          "numberOfApprovals": 1
        }
      ],
      "notificationChannel": ["EMAIL"]
    }
  
    res = self.session.post(f'{API_URL}/v2/review', json=data, headers={'x-csrf-token': self.csrf})
    res.raise_for_status()
    return res.json()['review']
  
  def get_review_request(self, review_id: str):
    res = self.session.get(f'{API_URL}/v2/review/{review_id}')
    res.raise_for_status()
  
    return res.json()['review']
  
  def is_approved(self, review_id: str):
    review = self.get_review_request(review_id)
    status = review['reviewStatus']
    if status == 'APPROVED':
        return True
    else:
        return False


if __name__ == "__main__":
  cs = Consensus("varia")
  res = cs.create_user_review_request("Testing consensus midway", "Just testing some consensus review creations.")
  print(res)

