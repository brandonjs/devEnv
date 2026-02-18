#!/bin/bash

AWS_FOLDER="$(brew --prefix awscli)"
AWS_BIN="$AWS_FOLDER/libexec/bin"
"$AWS_BIN/pip" install --upgrade requests
"$AWS_BIN/pip" install --upgrade git+ssh://git.amazon.com/pkg/BenderLibIsengard

CERT_FILE="$("$AWS_BIN"/python -c 'import requests ; print(requests.certs.where())')"
cp -v "$CERT_FILE" "$CERT_FILE.bak"
(
    security find-certificate -a -p ls "/System/Library/Keychains/SystemRootCertificates.keychain"
    security find-certificate -a -p ls "/Library/Keychains/System.keychain"
) > "$CERT_FILE"

CERT_FILE="$(ls -1 "$AWS_FOLDER"/libexec/lib/python*/site-packages/botocore/cacert.pem)"
cp -v "$CERT_FILE" "$CERT_FILE.bak"
(
    security find-certificate -a -p ls "/System/Library/Keychains/SystemRootCertificates.keychain"
    security find-certificate -a -p ls "/Library/Keychains/System.keychain"
) > "$CERT_FILE"

(security find-certificate -a -p ls /System/Library/Keychains/SystemRootCertificates.keychain \
    && security find-certificate -a -p ls /Library/Keychains/System.keychain) > "$HOME/.mac-ca-roots"

aws configure set default.ca_bundle "$HOME/.mac-ca-roots"
