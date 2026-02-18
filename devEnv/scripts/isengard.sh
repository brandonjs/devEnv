#!/bin/bash

account_id=$1
role_name=$2
echo "Enter token password"
read -s password
(/usr/bin/expect - << EOD
spawn java -jar isengard_cli.jar GetAssumeRoleCredentials "{\"AWSAccountID\":\"$account_id\",\"IAMRoleName\":\"$role_name\",\"SessionDuration\":\"43200\"}"
expect "Insert Token. Enter Password:"
send "$password\n"
expect eof
EOD
) | while read line; do
      if [[ "$line" =~ "AssumeRoleResult" ]]; then
         creds=`echo ${line} | sed -e 's/"{/{/g' -e 's/}"/}/g' | jq -r '.AssumeRoleResult' | jq -r '.credentials'`
         aak=`echo "${creds}" | jq -r '.accessKeyId'`
         ask=`echo "${creds}" | jq -r '.secretAccessKey'`
         tok=`echo "${creds}" | jq -r '.sessionToken'`
         echo "export AWS_ACCESS_KEY_ID=${aak}"
         echo "export AWS_SECRET_ACCESS_KEY=${ask}"
         echo "export AWS_SECURITY_TOKEN=${tok}"
      fi;
   done

exit
#aws iam list-users
