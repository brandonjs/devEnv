#!/bin/bash
#HOST=${1}
PASS_FILE="/Users/$USER/.softcert_temp_pass"

# Set this to your profile from /Users/${USER}/Library/Application Support/Firefox/Profiles/ and uncomment it.
FIREFOX_PROFILE=34kv8e9m.default-1519911607316
if [ -z ${FIREFOX_PROFILE:+x} ];
then
  echo "FIREFOX_PROFILE is not set!  Please set it to one of the directories in /Users/${USER}/Library/Application Support/Firefox/Profiles/"
  exit 1
fi

command -v certutil >/dev/null 2>&1 || { echo >&2 "I require certutil but it's not installed.  Please 'brew install nss'.  Aborting."; exit 1; }
command -v pk12util >/dev/null 2>&1 || { echo >&2 "I require pk12util but it's not installed.  Please 'brew install nss'.  Aborting."; exit 1; }

# create a temp file to hold the password then set it to user RW only
touch ${PASS_FILE}
chmod 600 ${PASS_FILE}

# Prompt for a password and store it in the temp file
read -s -p "What cert password would you like to use: " CERT_PASS
printf "\n"
cat <<EOF > ${PASS_FILE}
${CERT_PASS}
EOF

# Find the nickname of the most recent certificate stored in the Firefox DB.  This should always be the midway cert since new certs go at the bottom.
echo "##### Finding 'nickname' of your last certificate. #####"
mycert=`certutil -L -d "sql:/Users/$USER/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}" |cut -f1-8 -d ' ' | tail -n 1 | xargs`

# Export the cert and password it.
echo "##### Exporting certificate named ${mycert}. #####"
/usr/local/opt/nss/bin/pk12util -d "sql:/Users/$USER/Library/Application Support/Firefox/Profiles/${FIREFOX_PROFILE}" -n "$mycert" -o mycert.p12 -w ~/.softcert_temp_pass

# Break out the key and public key using the password
echo "##### Transforming certificate into private key. #####"
/usr/bin/openssl pkcs12 -in mycert.p12 -out key -nocerts -nodes -passin file:${PASS_FILE}
echo "##### Transforming certificate into public key. #####"
/usr/bin/openssl pkcs12 -in mycert.p12 -out public_key.crt -clcerts -nokeys -passin file:${PASS_FILE}

# Remove the temp pass file and the cert p12
rm -f mycert.p12
rm -f ${PASS_FILE}

# Remove the old cert files on the dev desktop if they exist
#echo "##### Removing old public and private key files from destination: ${HOST} #####"
#mssh $HOST rm -f .midway/public_key.crt .midway/key
rm -f ~/.midway/public_key.crt ~/.midway/key

# Copy the key and public key to the dev desktop
#echo "##### Copying public and private keys to destination: ${HOST} #####"
#mscp key $HOST:~/.midway/
#mscp public_key.crt $HOST:~/.midway/
cp key ~/.midway/
cp public_key.crt ~/.midway/

# Delete the local key and public key
rm -f key
rm -f public_key.crt

# Set permissions on the cert files
#echo "##### Setting permissions on destination public and private keys on destination: ${HOST} #####"
#mssh $HOST chmod 400 .midway/public_key.crt
#mssh $HOST chmod 400 .midway/key
chmod 400 ~/.midway/public_key.crt
chmod 400 ~/.midway/key

echo "##### Softcert setup complete. #####"

