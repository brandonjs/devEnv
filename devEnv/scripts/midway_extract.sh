#!/bin/bash
 
OPENSSL=openssl
CURL=curl
 
MIDWAY_DIR="${HOME}/.midway/"
MIDWAY_CERTIFICATE="${MIDWAY_DIR}certificate"
MIDWAY_PRIVATE_KEY="${MIDWAY_DIR}private_key"
 
if [ ! -d "${MIDWAY_DIR}" ]; then
  mkdir -p "${MIDWAY_DIR}"
fi
 
if [ ! -f "${MIDWAY_PRIVATE_KEY}" ]; then
  echo "generating a private key file... : ${MIDWAY_PRIVATE_KEY}" >&2
  $OPENSSL genrsa -out "${MIDWAY_PRIVATE_KEY}" 2048
  chmod 400 "${MIDWAY_PRIVATE_KEY}"
fi
 
echo "Creating SPKAC"
spkac=$($OPENSSL spkac -key "${MIDWAY_PRIVATE_KEY}")
spkac=${spkac:6}
 
echo "Uploading SPKAC"
cookie_file="/tmp/cookie"
midway_page=$($CURL -L -s --cookie-jar $cookie_file --negotiate -u : -k https://midway.amazon.com/legacy)
csrf_token=$(echo $midway_page | python -c "import sys, re; print(re.search('name=\"authenticity_token\" value=\"(.+?)\"', sys.stdin.read()).group(1))")
cert_result=$($CURL -L -s --cookie $cookie_file --negotiate -u : -k -A 'Midway_CLI_export' --data-urlencode "public_key=$spkac" --data-urlencode "authenticity_token=$csrf_token" https://midway.amazon.com/legacy/certificate/generate)
cert_num=$(echo $cert_result | perl -nle 'm/cert=([0-9]+)/; print $1')
rm $cookie_file
 
OUTFILE="${MIDWAY_DIR}$(date -u +%F)-${cert_num}.crt"
echo "Getting certificate (id $cert_num)"
$CURL -s --negotiate -u : -k -o "${OUTFILE}" "https://midway.amazon.com/legacy/certificate/${cert_num}/viewraw"
ln -sf "${OUTFILE}" "${MIDWAY_CERTIFICATE}"
