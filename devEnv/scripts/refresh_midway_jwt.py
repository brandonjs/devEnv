#!/Users/bsschwar/.pyenv/shims/python3
import os
import json
import subprocess
from base64 import urlsafe_b64decode as b64decode
from datetime import datetime, timezone
from pathlib import Path
from tempfile import NamedTemporaryFile

DOMAIN = "#HttpOnly_.midway-auth.amazon.com"
NAME = "amazon_enterprise_access"
COOKIE_FILE = Path.home() / ".midway" / "cookie"
assert COOKIE_FILE.is_file(), "Midway cookies file not present, run mwinit first"

COMMANDS = (
    ("/usr/hostidentity/bin/get_aea_jwt", "--getDataLongLived"),
    ("/usr/local/amazon/bin/acme_amazon_enterprise_access", "getAcmeDataLongLived"),
    ("/usr/hostidentity/bin/get_aea_jwt", "--getData"),
    ("/usr/local/amazon/bin/acme_amazon_enterprise_access", "getAcmeData"),
)

def jwt_token_expiration (token) -> datetime:
    header, body, *rest = [b64decode(c + "=" * (-len(c) % 4)) for c in token.split(".")]
    fields = json.loads(body)
    return datetime.fromtimestamp(fields["exp"], timezone.utc)

def new_posture ():
    for cmd in COMMANDS:
        if os.path.exists(cmd[0]):
            data = json.loads(subprocess.check_output(cmd))
            if data.get("Status", "") == "Success" and "Jwt" in data:
                return data["Jwt"]


posture_found = False
posture_updated = False
now = datetime.now(timezone.utc)

with NamedTemporaryFile("wt", dir=COOKIE_FILE.parent, delete=False) as w:
    temp = w.name
    with open(COOKIE_FILE, "rt") as r:
        for line_with_ending in r:
            line = line_with_ending.rstrip()
            try:
                domain, domspec, path, secure, ts, name, value, *rest = line.split("\t")
            except ValueError:
                domain = ""
            if domain == DOMAIN and path == "/" and name == NAME:
                posture_found = True
                expiry = datetime.fromtimestamp(int(ts, base=10), timezone.utc)
                local_expiry = expiry.astimezone()
                if now < expiry:
                    print(f"Posture cookie still valid, expires on {local_expiry:%Y-%m-%d at %H:%M:%S}")
                    break
                print(f"Posture cookie expired on {local_expiry:%Y-%m-%d at %H:%M:%S}")
                value = new_posture()
                expiry = jwt_token_expiration(value)
                local_expiry = expiry.astimezone()
                print("\t".join([domain, domspec, path, secure, f"{expiry.timestamp():.0f}", name, value, *rest]), file=w)
                print(f"Posture refreshed until {local_expiry:%Y-%m-%d at %H:%M:%S}")
                posture_updated = True
            else:
                print(line, file=w)
    if not posture_found:
        value = new_posture()
        expiry = jwt_token_expiration(value)
        local_expiry = expiry.astimezone()
        print(f"No posture cookie found, inserting new one expiring on {local_expiry:%Y-%m-%d at %H:%M:%S}")
        print("\t".join([DOMAIN, "TRUE", "/", "TRUE", f"{expiry.timestamp():.0f}", NAME, value]), file=w)
        posture_updated = True

if posture_updated:
    os.rename(temp, COOKIE_FILE)
else:
    os.remove(temp)
