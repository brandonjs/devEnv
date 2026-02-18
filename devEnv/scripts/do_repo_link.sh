#!/bin/bash
repo_link="/usr/local/bin/repo"
repo_file="/pkg/ice/sysadmin/ossi/bin/repo"
mailx=/usr/bin/mailx
admin=$(cat /var/adm/gv/admin_contact)
tFile=/tmp/already_sent_mail_about_repo
function mail_admin(){
   body=$1
   test -f $tFile && exit
   echo $body | $mailx -s "Issues with your system `hostname`" 
   touch $tFile
}
if [ -e $repo_link ] 
then 
   if [[ -L $repo_link  &&  "`readlink $repo_link > /dev/null 2>&1`" != "$repo_file" ]]
   then 
      mail_admin "Symlink already detected, not setup by us" 
   elif [ -f $repo_link ] 
   then 
      mail_admin "$repo_link exists, not replacing." 
   fi 
   mail_admin "$repo_link exists, not a file or symlink please take a look" 
else 
    ln -sf $repo_file $repo_link 
fi
