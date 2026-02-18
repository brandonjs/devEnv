#!/bin/bash -xv

if [ "`grep $2 /usr/NX/etc/users.db`" ]
then
    sed -i -e "/$2/d" /usr/NX/etc/users.db
fi
