#!/opt/homebrew/bin/bash

mwinit="mwinit -f"
sdel="ssh-add -D"
sadd="ssh-add"
sync="rsync -az --delete "
mp=".midway"
cloud_mkdir="cloud-desktop exec mkdir -p /home/${USER}/${mp} || true"
cloud_copy="cloud-desktop copy --source ${HOME}/${mp}/cookie --destination :/home/${USER}/${mp}/"
password=$(security find-generic-password -gs mway_pin 2>&1 | awk 'BEGIN{FS="\042"} /password/ {print $2}')

. ~/.env/functions.sh

${sdel}

echo ${password} | ${mwinit} -s
[[ $? != 0 ]] && echo "ERROR: Didn't auth properly to Midway" && exit
${sadd} 

#echo ${password} | ${mwinit} --cn
#[[ $? == 0 ]] && ${sadd} || echo "ERROR: Didn't auth properly to CN"

curl --connect-timeout 1 -f https://midway-auth-itar.amazon.com > /dev/null 2>&1
if [ $? == 0 ]; then
    echo "Trying ITAR"
    echo ${password} | ${mwinit} --itar
    ${sadd}
fi

echo "Copying cookie to cloud-desktop"
${cloud_mkdir}
${cloud_copy}
if [ $? != 0 ]; then
  cloud-desktop start --headless
  ${cloud_mkdir}
  ${cloud_copy}
fi

refresh_aea_cookie
