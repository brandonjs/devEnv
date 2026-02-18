#!/bin/bash
while [ ! -z "`mount | grep 10.43`" ]
do
   mount blrfiler01:/vol/eng_blr_gv/qct_gv /tmp/prj/qct/gv
   sleep 7
   while true
   do
      if [ -z "`fuser -mkv /tmp/prj/qct/gv | grep tmp_cleanup.pl`" ]
      then
         break
      fi
   done
umount /tmp/prj/qct/gv
umount /tmp/prj/qct/gv
done
