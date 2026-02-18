#!/bin/sh
################################################################################
# Copyright (c) 2010 Quest Software, Inc.  All Rights Reserved.
#
# vas_full_flush.sh
#
# Purpose:      This script will remove the current cache files and re-populate 
#               all information from scratch.
#
# Author(s):    Seth Ellsworth (seth.ellsworth@quest.com)
#
# Version:      0.4
#
# This script relies on internal knowledge of vasd's internal cache schema,
# which is undocumented and subject to change between releases.
#
################################################################################
# 0.4: set VGP for acmode if configured, don't use < _EOF style.
#
# 0.3: Don't work if VAS 4.0, not yet at least. 
#      Re-set vgp seccli policy if set ( thats Windows GP Host Access ). 
#                
# 0.2: Don't try to store vastool list users output, some shells complain after 
#      32K bytes of information.                
                

if [ -z "$DEBUG" ] ; then
    DEBUG=false
else
    DEBUG=true
fi

$DEBUG && set -x

VAS=/opt/quest/bin/vastool
VASD=/opt/quest/sbin/vasd
SQL=/opt/quest/libexec/vas/sqlite3
SQL3="$SQL -noheader -list -separator '|'"
IDENTDB=/var/opt/quest/vas/vasd/vas_ident.vdb
MISCDB=/var/opt/quest/vas/vasd/vas_misc.vdb
VGPCONF=/etc/opt/quest/vgp/vgp.conf
VGP=/opt/quest/bin/vgptool
ASDCOM=/opt/quest/libexec/vas/sugi/asdcom
TFILE=/tmp/_vas_full_flush.$$

UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
LOWER=abcdefghijklmnopqrstuvwxyz

CheckVasd ()
{
    $DEBUG && set -x
    sleep 1
    COUNT=0
    $VAS list users 2>&1 | grep "ERROR: Could not" >/dev/null
    if [ "$?" -eq 0 ] ; then
# matched, so start looping
        while test $COUNT -le 10 ; do
            sleep 1
            $VAS list users 2>&1 | grep "ERROR: Could not" >/dev/null
            if [ "$?" -ne 0 ] ; then
                break
            fi
            COUNT=`expr $COUNT + 1`
        done
    fi
}

StartVasd ()
{
    $DEBUG && set -x
    if [ -f /etc/init.d/vasd ] ; then
        /etc/init.d/vasd start
    else
        if [ -f /etc/rc.d/init.d/vasd ] ; then
            /etc/rc.d/init.d/vasd start
        else
            /sbin/init.d/vasd start
        fi
    fi
    CheckVasd
}

StopVasd ()
{
    $DEBUG && set -x
    if [ -f /etc/init.d/vasd ] ; then
        /etc/init.d/vasd stop
    else
        if [ -f /etc/rc.d/init.d/vasd ] ; then
            /etc/rc.d/init.d/vasd stop
        else
            /sbin/init.d/vasd stop
        fi
    fi
}

# First thing, check for root.
if [ "`id | sed 's/uid=\([0-9]*\).*/\1/'`" -ne 0 ] ; then
    echo "Must be run as root."
    exit 2
fi

if [ -f $ASDCOM ] ; then
    echo "Does not work with QAS 4.0 ( yet )"
    exit 2
fi

# Stop vasd from interfering. 
StopVasd

# Blow away the old files. 
echo "Removing old caches"
rm -rf $IDENTDB $MISCDB

# From wherever needed pull the bits of information that vas won't re-populate into the misc cache. 
echo "Bootstrapping misc cache"
REALM=`$VAS info domain`
FQDN=`$VAS ktutil list | grep "host/.*\..*@" | head -1 | awk '{print $3}' | sed 's/host\/\([^@]*\)@.*/\1/'`
CNAME=`echo $FQDN | cut -d. -f1 | tr $LOWER $UPPER`

# Set them in the DB. ( The info domain call above re-created the misc cache already )
printf ".timeout 15000\n" > $TFILE
printf "insert into misc values('computerFQDN','$FQDN');\n" >> $TFILE
printf "insert into misc values('computerName','$CNAME');\n" >> $TFILE
printf "insert into misc values('defaultRealm','$REALM');\n" >> $TFILE
if [ -f $VGP -a -f $VGPCONF ] ; then
    grep -i "^[ \t]*ApplyWindowsHostAccess[ \t]*=[ \t]*true" < $VGPCONF >/dev/null
    if [ $? -eq 0 ] ; then
        printf "insert into misc values('accessControlMode','VGP');\n" >> $TFILE
    fi
fi
printf ".q\n" >> $TFILE
echo | $SQL3 -init $TFILE $MISCDB

# Do this BEFORE forest root, otherwise its not detected properly.
# ( The resolution algorithms will hit AD if forest root is missing,
#   but dont' for site if forest root is already present. )        
SITE=`$VAS info site`
printf ".timeout 15000\ninsert into misc values('localSite','$SITE');\n.q\n" | $SQL3 $MISCDB

# A little boot-strapping goign on here, the above lets this next command work.
FORESTROOT=`$VAS -u host/ info forest-root`
printf ".timeout 15000\ninsert into misc values('forestRoot','$FORESTROOT');\n.q\n" | $SQL3 $MISCDB

# Another thing only a join does. ( hmmm.. wouldn't a flush also check this? not sure now why I 
# added this originally, probably from my do_deep_dark function in the 2.6->3.0 migration script,
# checking those notes... ok: "Populate the schema cache so we load from the right attributes."
# Ok, helps boot strap other things as well. 
$VAS -u host/ schema cache

# This helps generate the user/group cache initially, normally done by vastool join.
echo "Creating initial user cache"
$VAS list users >/dev/null 2>&1
echo "Creating initial group cache"
$VAS list groups >/dev/null 2>&1

# The guts of a vastool flush, loads up the cache. 
$VASD -xugsn

# Start vasd, let everythign just move on.
StartVasd

# Test for VGP, and the ApplyWindowsHostAccess setting. 
if [ -f $VGP -a -f $VGPCONF ] ; then
    grep -i "^[ \t]*ApplyWindowsHostAccess[ \t]*=[ \t]*true" < $VGPCONF >/dev/null
    if [ $? -eq 0 ] ; then
        # Yes, ApplyWindowsHostAccess enabled, re-apply it. 
        echo "Applying VGP Windows Host Access policies"
        $VGP unapply vgp_scecli
        $VGP apply vgp_scecli
    fi
fi

rm -f $TFILE
