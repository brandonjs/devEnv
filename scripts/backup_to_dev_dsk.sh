#!/bin/bash

DESKTOP="dev-dsk-bsschwar-1e-15f33a8e.us-east-1.amazon.com"
JQ="/opt/homebrew/bin/jq"
auth=$(curl -sL --cookie ~/.midway/cookie --cookie-jar ~/.midway/cookie 'https://midway-auth.amazon.com/api/session-status' | ${JQ} .authenticated)

[[ ${auth} != "true" ]] && echo "Not Midway authenticated, exiting." && exit 0

rsync -avzL --exclude-from=/Users/bsschwar/scripts/backup_to_dev_dsk.excludes --delete -b --backup-dir="/home/bsschwar/MacBackup/archives/$(date +"%Y-%m-%d_%H%M")" ~/ ${DESKTOP}:/home/bsschwar/MacBackup/current/

