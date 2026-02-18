#!/bin/bash

for i in /usr/bin/rsync /usr/local/sbin/rsync
do
   [ -x $i ] && RSYNC="$i" && break
done
OPTS="--quiet --recursive --links --perms --times -D --delete --timeout=300 --exclude=releases --exclude=experimental"
#OPTS="-avD --delete --timeout=300 --exclude=releases --exclude=experimental"
SRC="rsync://mirror.anl.gov/gentoo/"
DST="/prj/qct/quic/chrome-mirror/gentoo-distfiles/"
LOG=/tmp/rsync-gentoo-portage.log

echo "Started update at" `date` >> $LOG 2>&1
logger -t rsync "re-rsyncing the gentoo-portage tree"
${RSYNC} ${OPTS} ${SRC} ${DST} >> $LOG 2>&1

OPTS="--quiet --recursive --links --perms --times -D --delete --timeout=300 --exclude=releases --exclude=experimental"
#OPTS="-avD --delete --timeout=300 --exclude=releases --exclude=experimental"
SRC="rsync://commondatastorage.googleapis.com/chromeos-localmirror"
DST="/prj/qct/quic/chrome-mirror/chromeos-localmirror/"
LOG=/tmp/rsync-gentoo-portage.log

echo "Started update at" `date` >> $LOG 2>&1
logger -t rsync "re-rsyncing the gentoo-portage tree"
${RSYNC} ${OPTS} ${SRC} ${DST} >> $LOG 2>&1
echo "End: "`date` >> $0.log 2>&1
