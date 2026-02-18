#!/bin/bash

limit=$1
count=1
while true
do
    echo "start ssh connection " $count
    ssh brandons@www.codeaurora.org "hostname; find /caf/git/repos/git_base/admin/config.git/ > /dev/null" &
    count=`expr $count + 1`
    if [ $count -ge $limit ]
    then
        break
    fi
done
echo "Done."
