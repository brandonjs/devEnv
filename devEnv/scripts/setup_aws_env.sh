#!/bin/bash -xv

while getopts "r:p:" OPTION; do
    case $OPTION in
        a)
            account=$OPTARG
            ;;
        r)
            role=$OPTARG
            ;;
        p)
            profile=$OPTARG
            ;;
        *)
            echo "Incorrect options provided"
            return
            ;;
    esac
done

now=$(date -u +%s)
expire=0

[ -z "$role" ] && role="Admin"
[ -z "$profile" ] && profile=`whoami`
[ -z "$account" ] && account="971593487406"
if [ -f "/tmp/creds" ]; then
    creds=`jq -r ."Credentials" /tmp/creds`
    if [ -n "${creds}" ]; then
        expire=`date -u -j -f%Y-%m-%dT%H:%M:%SZ $(echo $creds | jq -r ."Expiration") +%s`
    fi
fi

if [ ! -f "/tmp/creds" ] || [ "${expire}" == 0 ] || [ $(expr $expire - $now) -lt 0 ]; then
    #aws --profile ${profile} sts assume-role --duration-seconds 36000 --role-arn arn:aws:iam::${account}:role/${role} --role-session-name bsschwar-console > /tmp/creds
    aws sts assume-role --duration-seconds 36000 --role-arn arn:aws:iam::${account}:role/${role} --role-session-name bsschwar-console > /tmp/creds
    [ $? != 0 ] && echo "Can't assume-role, have to run mwinit?" && return
fi
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

export AWS_ACCESS_KEY_ID=$(jq -r ."Credentials"."AccessKeyId" /tmp/creds)
export AWS_SECRET_ACCESS_KEY=$( jq -r ."Credentials"."SecretAccessKey" /tmp/creds)
export AWS_SESSION_TOKEN=$(jq -r ."Credentials"."SessionToken" /tmp/creds)
